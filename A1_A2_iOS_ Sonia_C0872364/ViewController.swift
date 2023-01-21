//
//  ViewController.swift
//  A1_A2_iOS_ Sonia_C0872364
//
//  Created by Sonia Nain on 2023-01-20.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    @IBOutlet weak var map: MKMapView!
    var locationManager = CLLocationManager()
    var dropPinCount = 1
    var locationsArr = [CLLocationCoordinate2D]()
    var titleArr = [1: "A", 2: "B", 3: "C"]
    var userCoordinates = CLLocationCoordinate2D()
    @IBOutlet weak var directionBtn: UIButton!
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    
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
        
        directionBtn.layer.cornerRadius = 0.5 * directionBtn.bounds.size.width
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        locationSearchTable.mapView = map
        locationSearchTable.handleMapSearchDelegate = self
        
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
        
        let touchPoint = sender.location(in: map)
        let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
        
        handleDropPin(_coordinate: coordinate)
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
                rendrer.strokeColor = UIColor.systemOrange
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
    
    
    // Display the distance between the two markers on a label beside each polyline.
    
    func displayDistanceBetweenTwoMarkers(){

        let distanceFirst = calculateDistanceBetweenTwoPoints(_coordinateFirst: locationsArr[0], _coordinateSecond: locationsArr[1])
        let distanceSecond = calculateDistanceBetweenTwoPoints(_coordinateFirst: locationsArr[1], _coordinateSecond: locationsArr[2])
        let distanceThird = calculateDistanceBetweenTwoPoints(_coordinateFirst: locationsArr[2], _coordinateSecond: locationsArr[0])
        
        // display distance between first two points
        
        let latitudeMidOne = ((locationsArr[0].latitude + locationsArr[1].latitude) / 2)
        let longitudeMidOne = ((locationsArr[0].longitude + locationsArr[1].longitude) / 2)
        
        let location1 = CLLocationCoordinate2D(latitude: latitudeMidOne, longitude: longitudeMidOne)
        let annotation1 = MKPointAnnotation()
        annotation1.title = String(distanceFirst) + "Km"
        annotation1.subtitle = "Distance Label"
        annotation1.coordinate = location1
        map.addAnnotation(annotation1)
        // display distance between second third points
        
        let latitudeMidTwo = ((locationsArr[1].latitude + locationsArr[2].latitude) / 2)
        let longitudeMidTwo = ((locationsArr[1].longitude + locationsArr[2].longitude) / 2)
        
        let location2 = CLLocationCoordinate2D(latitude: latitudeMidTwo, longitude: longitudeMidTwo)
        let annotation2 = MKPointAnnotation()
        annotation2.title = String(distanceSecond) + "Km"
        annotation2.subtitle = "Distance Label"
        annotation2.coordinate = location2
        map.addAnnotation(annotation2)
        
        // display distance between second third points
        
        let latitudeMidThree = ((locationsArr[2].latitude + locationsArr[0].latitude) / 2)
        let longitudeMidThree = ((locationsArr[2].longitude + locationsArr[0].longitude) / 2)
        
        let location3 = CLLocationCoordinate2D(latitude: latitudeMidThree, longitude: longitudeMidThree)
        let annotation3 = MKPointAnnotation()
        annotation3.title = String(distanceThird) + "Km"
        annotation3.subtitle = "Distance Label"
        annotation3.coordinate = location3
        map.addAnnotation(annotation3)
        
    }
    

    @IBAction func drawRoutes(_ sender: UIButton) {
        
        map.removeOverlays(map.overlays)
        
        self.map.annotations.forEach {
          if !($0 is MKUserLocation) && ($0.subtitle == "Distance Label" ) {
            self.map.removeAnnotation($0)
          }
        }
        
        // draw 1st route
        fetchRoutes(_startCoordinate: locationsArr[0], _endCoordinate: locationsArr[1])
        
        // draw 2nd route
        fetchRoutes(_startCoordinate: locationsArr[1], _endCoordinate: locationsArr[2])
        
        // draw 3rd route
        fetchRoutes(_startCoordinate: locationsArr[2], _endCoordinate: locationsArr[0])
    }
    
    func fetchRoutes(_startCoordinate : CLLocationCoordinate2D, _endCoordinate : CLLocationCoordinate2D){
        
        let sourcePlaceMark1 = MKPlacemark(coordinate: _startCoordinate)
        let destinationPlaceMark2 = MKPlacemark(coordinate: _endCoordinate)
        
        // request a direction
        let directionRequest = MKDirections.Request()
        
        // assign the source and destination properties of the request
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark1)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark2)
        
        // transportation type
        directionRequest.transportType = .automobile
        
        // calculate the direction
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            // create the route
            let route = directionResponse.routes[0]
            // drawing a polyline
            self.map.addOverlay(route.polyline, level: .aboveRoads)
            
            // define the bounding map rect
            let rect = route.polyline.boundingMapRect
            self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
        }
        
    }
    
    func handleDropPin(_coordinate: CLLocationCoordinate2D){
        
        if( dropPinCount == 4){
            map.removeOverlays(map.overlays)
            
            self.map.annotations.forEach {
              if !($0 is MKUserLocation) {
                self.map.removeAnnotation($0)
              }
            }
            
            dropPinCount = 1
            locationsArr.removeAll()
            directionBtn.isHidden = true
            
        }
        
        if(dropPinCount <= 3){
            // add annotation
            
            let annotation = MKPointAnnotation()
            annotation.title = titleArr[dropPinCount]
            annotation.coordinate = _coordinate
            map.addAnnotation(annotation)
            
            // add coordinate to locationArr
            
            locationsArr.append(_coordinate)
            
        }
        
        if( dropPinCount == 3){
            addPolygon()
            displayDistanceBetweenTwoMarkers()
            directionBtn.isHidden = false
        }
        
        dropPinCount += 1
    }


}

extension ViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark:MKPlacemark){
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        map.setRegion(region, animated: true)
        
        handleDropPin(_coordinate: placemark.coordinate)
    }
}
