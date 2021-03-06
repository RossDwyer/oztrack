package org.oztrack.controller;

import java.io.Serializable;
import java.util.List;

import org.oztrack.data.access.UserDao;
import org.oztrack.data.model.Project;
import org.oztrack.data.model.ProjectUser;
import org.oztrack.data.model.User;
import org.oztrack.data.model.types.ProjectAccess;
import org.oztrack.data.model.types.Role;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.PermissionEvaluator;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.stereotype.Service;

@Service
public class OzTrackPermissionEvaluator implements PermissionEvaluator {
    @Autowired
    private UserDao userDao;

    @Override
    public boolean hasPermission(Authentication authentication, Object targetDomainObject, Object permission) {
        User currentUser = getAuthenticatedUser(authentication);
        if ((currentUser != null) && (currentUser.getAdmin() != null) && currentUser.getAdmin()) {
            return true;
        }
        if (targetDomainObject == null) {
            return false;
        }
        if (targetDomainObject instanceof Project) {
            return hasProjectPermission(currentUser, (Project) targetDomainObject, permission);
        }
        return false;
    }

    public User getAuthenticatedUser(Authentication authentication) {
        if (
            (authentication == null) ||
            !authentication.isAuthenticated() ||
            !authentication.getAuthorities().contains(new SimpleGrantedAuthority("ROLE_USER"))
        ) {
            return null;
        }
        return userDao.getByUsername((String) authentication.getPrincipal());
    }

    private boolean hasProjectPermission(User currentUser, Project project, Object permission) {
        if (permission.equals("read") && (project.getAccess() == ProjectAccess.OPEN)) {
            return true;
        }
        if (currentUser == null) {
            return false;
        }
        List<ProjectUser> projectUsers = project.getProjectUsers();
        for (ProjectUser projectUser : projectUsers) {
            if (!projectUser.getUser().equals(currentUser)) {
                continue;
            }
            if (permission.equals("read")) {
                if (
                    (projectUser.getRole() == Role.READER) ||
                    (projectUser.getRole() == Role.WRITER) ||
                    (projectUser.getRole() == Role.MANAGER)
                ) {
                    return true;
                }
            }
            else if (permission.equals("write")) {
                if (
                    (projectUser.getRole() == Role.WRITER) ||
                    (projectUser.getRole() == Role.MANAGER)
                ) {
                    return true;
                }
            }
            else if (permission.equals("manage")) {
                if (projectUser.getRole() == Role.MANAGER) {
                    return true;
                }
            }
        }
        return false;
    }

    @Override
    public boolean hasPermission(Authentication authentication, Serializable targetId, String targetType, Object permission) {
        return false;
    }
}