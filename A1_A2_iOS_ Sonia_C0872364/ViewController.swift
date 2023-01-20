//
//  ViewController.swift
//  A1_A2_iOS_ Sonia_C0872364
//
//  Created by Sonia Nain on 2023-01-20.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var locationManager = CLLocationManager()
    var dropPinCount = 1
    var locationsArr = [CLLocationCoordinate2D]()
    var titleArr = [1: "A", 2: "B", 3: "C"]
    var userCoordinates = CLLocationCoordinate2D()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // map zooming
        map.isZoomEnabled = true
        map.showsUserLocation = true
        map.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        addSingleTap()
    }
    
    // location manager
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0]
        userCoordinates = userLocation.coordinate
        let latitude = userCoordinates.latitude
        let longitude = userCoordinates.longitude
        
        displayLocation(latitude: latitude, longitude: longitude, title: "User Location", subtitle: "you are here")
        
    }
    
    func displayLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, title: String, subtitle: String) {
        // 2 - define delta latitude and delta longitude for the span
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees = 0.05
        
        // 3 - creating the span and location coordinate and finally the region
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        let loc: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
        // 4 - set region for the map
        map.setRegion(region, animated: true)
        let annotation = MKPointAnnotation()
        annotation.title = title
        
        CLGeocoder().reverseGeocodeLocation(loc) { (placemarks, error) in
            if error != nil {
                print(error!)
            } else {
                if let placemark = placemarks?[0] {
                    
                    annotation.title = placemark.subThoroughfare! + " " + placemark.thoroughfare! + ", " + placemark.locality! + ", " + placemark.country!
                }
            }
        }
        
        annotation.coordinate = location
        map.addAnnotation(annotation)
        
    }
    
    //MARK: - viewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
//        if annotation is MKUserLocation {
//            return nil
//        }
        
        switch annotation.title {
        case "User Location":
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
            annotationView.pinTintColor = #colorLiteral(red: 0.2588235438, green: 0.7568627596, blue: 0.9686274529, alpha: 1)
            annotationView.canShowCallout = true
            return annotationView
        case "A", "B", "C" :
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            annotationView.animatesDrop = true
            annotationView.pinTintColor = #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1)
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        case "my favorite":
            let annotationView = map.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKPinAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return annotationView
        default:
            return nil
        }
    }
    
    //MARK: - single tap func
    func addSingleTap() {
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        singleTap.numberOfTapsRequired = 1
        map.addGestureRecognizer(singleTap)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        
        if(dropPinCount <= 3){
            // add annotation
            let touchPoint = sender.location(in: map)
            let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
            let annotation = MKPointAnnotation()
            annotation.title = titleArr[dropPinCount]
            annotation.coordinate = coordinate
            map.addAnnotation(annotation)
            
            // add coordinate to locationArr
            
            locationsArr.append(coordinate)
            
        }
        
        if( dropPinCount == 3){
            addPolygon()
            
        }
        
        dropPinCount += 1
        //destination = coordinate
    }
    
    //MARK: - polygon method
    func addPolygon() {
        let polygon = MKPolygon(coordinates: locationsArr, count: locationsArr.count)
        map.addOverlay(polygon)
    }
    
    //MARK: - rendrer for overlay func
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKCircle {
                let rendrer = MKCircleRenderer(overlay: overlay)
                rendrer.fillColor = UIColor.black.withAlphaComponent(0.5)
                rendrer.strokeColor = UIColor.green
                rendrer.lineWidth = 2
                return rendrer
            } else if overlay is MKPolyline {
                let rendrer = MKPolylineRenderer(overlay: overlay)
                rendrer.strokeColor = UIColor.blue
                //rendrer.lineDashPattern = transportVal == .walking ? [0,10]: []
                rendrer.lineWidth = 3
                return rendrer
            } else if overlay is MKPolygon {
                let rendrer = MKPolygonRenderer(overlay: overlay)
                rendrer.fillColor = UIColor.red.withAlphaComponent(0.6)
                rendrer.strokeColor = UIColor.green
                rendrer.lineWidth = 2
                return rendrer
            }
            return MKOverlayRenderer()
        }
    
    
    //MARK: - callout accessory control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        let viewCoordinate = view.annotation?.coordinate
        let annotationTitle = (view.annotation?.title ?? "")!
        let distance = calculateDistanceBetweenTwoPoints(_coordinateFirst: viewCoordinate!, _coordinateSecond: userCoordinates)
        let message = "The distance between your location and Point " + annotationTitle + ": " + String(distance) + "Km"
        
        let alertController = UIAlertController(title: "Distance Between Two Points", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // Calculate distance between two points
    
    func calculateDistanceBetweenTwoPoints(_coordinateFirst: CLLocationCoordinate2D, _coordinateSecond: CLLocationCoordinate2D ) -> Int{
        
        let coordinate1 = CLLocation(latitude: _coordinateFirst.latitude, longitude: _coordinateFirst.longitude)
        let coordinate2 = CLLocation(latitude: _coordinateSecond.latitude, longitude: _coordinateSecond.longitude)
        
        let distance = coordinate1.distance(from: coordinate2)/1000
        
        return Int(distance)
        
    }


}

