package org.oztrack.view;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.geotools.data.simple.SimpleFeatureCollection;
import org.geotools.feature.FeatureCollections;
import org.geotools.feature.simple.SimpleFeatureBuilder;
import org.geotools.feature.simple.SimpleFeatureTypeBuilder;
import org.geotools.geometry.jts.JTSFactoryFinder;
import org.opengis.feature.simple.SimpleFeature;
import org.opengis.feature.simple.SimpleFeatureType;
import org.oztrack.app.Constants;
import org.oztrack.data.model.Animal;
import org.oztrack.data.model.PositionFix;

import com.vividsolutions.jts.geom.Coordinate;
import com.vividsolutions.jts.geom.GeometryFactory;
import com.vividsolutions.jts.geom.MultiPoint;

public class AnimalDetectionsFeatureBuilder {
    private static class AnimalDetections {
        private Animal animal;
        private Date fromDate;
        private Date toDate;
        private List<Coordinate> nondeletedCoordinates;
        private List<Coordinate> deletedCoordinates;
    }

    private final SimpleDateFormat isoDateFormat = new SimpleDateFormat("yyyy-MM-dd");
    private final GeometryFactory geometryFactory = JTSFactoryFinder.getGeometryFactory(null);
    private final List<PositionFix> positionFixList;
    private final boolean includeDeleted;

    public AnimalDetectionsFeatureBuilder(List<PositionFix> positionFixList, boolean includeDeleted) {
        this.positionFixList = positionFixList;
        this.includeDeleted = includeDeleted;
    }

    public SimpleFeatureCollection buildFeatureCollection() {
        List<AnimalDetections> animalDetectionsList = buildAnimalDetectionsList();
        SimpleFeatureType featureType = buildFeatureType(4326);
        SimpleFeatureCollection featureCollection = FeatureCollections.newCollection();
        for (AnimalDetections animalDetections : animalDetectionsList) {
            featureCollection.add(buildFeature(featureType, animalDetections, false));
            if (includeDeleted) {
                featureCollection.add(buildFeature(featureType, animalDetections, true));
            }
        }
        return featureCollection;
    }

    private List<AnimalDetections> buildAnimalDetectionsList() {
        List<AnimalDetections> animalDetectionsList = new ArrayList<AnimalDetections>();
        AnimalDetections animalDetections = null;
        for (PositionFix positionFix : positionFixList) {
            if ((animalDetections == null) || (animalDetections.animal.getId() != positionFix.getAnimal().getId())) {
                animalDetections = new AnimalDetections();
                animalDetections.animal = positionFix.getAnimal();
                animalDetections.fromDate = null;
                animalDetections.toDate = null;
                animalDetections.nondeletedCoordinates = new ArrayList<Coordinate>();
                animalDetections.deletedCoordinates = new ArrayList<Coordinate>();
                animalDetectionsList.add(animalDetections);
            }
            if (includeDeleted || !positionFix.getDeleted()) {
                if (animalDetections.fromDate == null) {
                    animalDetections.fromDate = positionFix.getDetectionTime();
                }
                animalDetections.toDate = positionFix.getDetectionTime();
            }
            if (positionFix.getDeleted()) {
                animalDetections.deletedCoordinates.add(positionFix.getLocationGeometry().getCoordinate());
            }
            else {
                animalDetections.nondeletedCoordinates.add(positionFix.getLocationGeometry().getCoordinate());
            }
        }
        return animalDetectionsList;
    }

    private SimpleFeatureType buildFeatureType(Integer srid) {
        SimpleFeatureTypeBuilder featureTypeBuilder = new SimpleFeatureTypeBuilder();
        featureTypeBuilder.setName("Detections");
        featureTypeBuilder.setNamespaceURI(Constants.namespaceURI);
        featureTypeBuilder.add("animalId", Long.class);
        featureTypeBuilder.add("fromDate", String.class);
        featureTypeBuilder.add("toDate", String.class);
        featureTypeBuilder.add("deleted", Boolean.class);
        featureTypeBuilder.add("multiPoint", MultiPoint.class, srid);
        SimpleFeatureType featureType = featureTypeBuilder.buildFeatureType();
        return featureType;
    }

    private SimpleFeature buildFeature(SimpleFeatureType featureType, AnimalDetections animalDetections, boolean deleted) {
        SimpleFeatureBuilder featureBuilder = new SimpleFeatureBuilder(featureType);
        featureBuilder.set("animalId", animalDetections.animal.getId());
        featureBuilder.set("fromDate", (animalDetections.fromDate == null) ? null : isoDateFormat.format(animalDetections.fromDate));
        featureBuilder.set("toDate", (animalDetections.toDate == null) ? null : isoDateFormat.format(animalDetections.toDate));
        featureBuilder.set("deleted", deleted);
        List<Coordinate> coordinates = deleted ? animalDetections.deletedCoordinates : animalDetections.nondeletedCoordinates;
        featureBuilder.set("multiPoint", geometryFactory.createMultiPoint(coordinates.toArray(new Coordinate[] {})));
        String featureId = animalDetections.animal.getId().toString() + "-" + (deleted ? "deleted" : "nondeleted");
        return featureBuilder.buildFeature(featureId);
    }
}