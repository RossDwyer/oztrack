package org.oztrack.data.access.impl;

import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.List;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import javax.persistence.Query;

import org.apache.commons.lang3.Range;
import org.apache.commons.lang3.time.DateUtils;
import org.geotools.geometry.jts.JTSFactoryFinder;
import org.oztrack.data.access.ProjectDao;
import org.oztrack.data.model.Project;
import org.oztrack.data.model.ProjectUser;
import org.oztrack.data.model.User;
import org.oztrack.data.model.types.ProjectAccess;
import org.oztrack.data.model.types.Role;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.Polygon;
import com.vividsolutions.jts.io.WKTReader;

@Service
public class ProjectDaoImpl implements ProjectDao {
    private EntityManager em;

    @PersistenceContext
    public void setEntityManger(EntityManager em) {
        this.em = em;
    }

    @Override
    public List<Project> getAll() {
        @SuppressWarnings("unchecked")
        List<Project> resultList = em.createQuery("from Project").getResultList();
        return resultList;
    }

    @Override
    public Project getProjectById(Long id) {
        @SuppressWarnings("unchecked")
        List<Project> resultList = em
            .createQuery("from Project where id = :id")
            .setParameter("id", id)
            .getResultList();
        return resultList.isEmpty() ? null : resultList.get(0);
    }

    @Override
    public Project getProjectByTitle(String title) {
        @SuppressWarnings("unchecked")
        List<Project> resultList = em
            .createQuery("from Project where title = :title")
            .setParameter("title", title)
            .getResultList();
        return resultList.isEmpty() ? null : resultList.get(0);
    }

    @Override
    @Transactional
    public void save(Project object) {
        object.setUpdateDate(new java.util.Date());
        em.persist(object);
    }

    @Override
    @Transactional
    public Project update(Project object) {
        object.setUpdateDate(new java.util.Date());
        return em.merge(object);
    }

    @Override
    @Transactional
    public void delete(Project project) {
        em.remove(project);
    }

    @Override
    @Transactional
    public void create(Project project, User currentUser) throws Exception {
        // create/update details
        project.setCreateDate(new java.util.Date());
        project.setCreateUser(currentUser);
        project.setDataSpaceAgent(currentUser);

        // set the current user to be an admin for this project
        ProjectUser adminProjectUser = new ProjectUser();
        adminProjectUser.setProject(project);
        adminProjectUser.setUser(currentUser);
        adminProjectUser.setRole(Role.MANAGER);

        // add this user to the project's list of users
        List <ProjectUser> projectProjectUsers = project.getProjectUsers();
        projectProjectUsers.add(adminProjectUser);
        project.setProjectUsers(projectProjectUsers);

        // save it all - project first
        save(project);

        project.setDataDirectoryPath("project-" + project.getId().toString());
        update(project);
    }

    @Override
    public Range<Date> getDetectionDateRange(Project project, boolean includeDeleted) {
        String sql =
            "select min(o.detectionTime), max(o.detectionTime)\n" +
            "from PositionFix o\n" +
            "where ((o.deleted = false) or (:includeDeleted = true))\n" +
            "and o.dataFile in (select d from datafile d where d.project.id = :projectId)";
        Query query = em.createQuery(sql);
        query.setParameter("projectId", project.getId());
        query.setParameter("includeDeleted", includeDeleted);
        Object[] result = (Object[]) query.getSingleResult();
        Date fromDate = (Date) result[0];
        Date toDate = (Date) result[1];
        return ((fromDate == null) || (toDate == null)) ? null : Range.between(fromDate, toDate);
    }

    @Override
    public int getDetectionCount(Project project, boolean includeDeleted) {
        String sql =
            "select count(*)\n" +
            "from PositionFix o\n" +
            "where ((o.deleted = false) or (:includeDeleted = true))\n" +
            "and o.dataFile in (select d from datafile d where d.project.id = :projectId)";
        Query query = em.createQuery(sql);
        query.setParameter("projectId", project.getId());
        query.setParameter("includeDeleted", includeDeleted);
        return ((Number) query.getSingleResult()).intValue();
    }

    @Override
    public Polygon getBoundingBox(Project project) {
        String geomExpr = project.getCrosses180()
            ? "ST_Shift_Longitude(positionfix.locationgeometry)"
            : "positionfix.locationgeometry";
        Query query = em.createNativeQuery(
            "select ST_AsText(ST_Envelope(ST_Collect(" + geomExpr + ")))\n" +
            "from datafile, positionfix\n" +
            "where datafile.project_id = :projectId\n" +
            "and positionfix.datafile_id = datafile.id\n" +
            "and not(positionfix.deleted)"
        );
        query.setParameter("projectId", project.getId());
        String wkt = (String) query.getSingleResult();
        if (wkt == null) {
            return null;
        }
        GeometryFactory geometryFactory = JTSFactoryFinder.getGeometryFactory(null);
        WKTReader reader = new WKTReader(geometryFactory);
        Polygon polygon;
        try {
            polygon = (Polygon) reader.read(wkt);
        }
        catch (Exception e) {
            return null;
        }
        return polygon;
    }

    @Override
    public HashMap<Long, Polygon> getAnimalBoundingBoxes(Project project) {
        String geomExpr = project.getCrosses180()
            ? "ST_Shift_Longitude(positionfix.locationgeometry)"
            : "positionfix.locationgeometry";
        Query query = em.createNativeQuery(
            "select animal.id, ST_AsText(ST_Envelope(ST_Collect(" + geomExpr + ")))\n" +
            "from animal\n" +
            "inner join positionfix on\n" +
            "    positionfix.animal_id = animal.id and\n" +
            "    not(positionfix.deleted)\n" +
            "where\n" +
            "    animal.project_id = :projectId\n" +
            "group by animal.id;"
        );
        query.setParameter("projectId", project.getId());
        GeometryFactory geometryFactory = JTSFactoryFinder.getGeometryFactory(null);
        WKTReader reader = new WKTReader(geometryFactory);
        HashMap<Long, Polygon> map = new HashMap<Long, Polygon>();
        @SuppressWarnings("unchecked")
        List<Object[]> resultList = query.getResultList();
        for (Object[] result : resultList) {
            Long animalId = ((Number) result[0]).longValue();
            String wkt = (String) result[1];
            Polygon polygon = null;
            if (wkt != null) {
                try {
                    polygon = (Polygon) reader.read(wkt);
                }
                catch (Exception e) {
                }
            }
            map.put(animalId, polygon);
        }
        return map;
    }

    @Override
    public List<Project> getProjectsByAccess(ProjectAccess access) {
        @SuppressWarnings("unchecked")
        List<Project> resultList = em
            .createQuery("from Project where access = :access order by createDate")
            .setParameter("access", access)
            .getResultList();
        return resultList;
    }

    @Override
    public List<ProjectUser> getProjectUsersWithRole(Project project, Role role) {
        @SuppressWarnings("unchecked")
        List<ProjectUser> resultList = em
            .createQuery(
                "from org.oztrack.data.model.ProjectUser\n" +
                "where project = :project and role = :role\n" +
                "order by user.lastName, user.firstName")
            .setParameter("project", project)
            .setParameter("role", role)
            .getResultList();
        return resultList;
    }

    @Override
    public List<Project> getProjectsWithExpiredEmbargo(Date expiryDate) {
        @SuppressWarnings("unchecked")
        List<Project> resultList = em
            .createQuery(
                "from org.oztrack.data.model.Project\n" +
                "where access = 'EMBARGO' and :expiryDate >= embargoDate"
            )
            .setParameter("expiryDate", DateUtils.truncate(expiryDate, Calendar.DATE))
            .getResultList();
        return resultList;
    }
}
