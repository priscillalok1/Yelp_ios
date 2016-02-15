//
//  MapViewController.swift
//  Yelp
//
//  Created by Priscilla Lok on 2/14/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    var businesses: [Business]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if businesses != nil {
            for business in businesses {
                let businessCoordinate = business.coordinate
                let longitude = businessCoordinate["longitude"]
                let latitude = businessCoordinate["latitude"]
                let businessLocation = CLLocationCoordinate2DMake(latitude!, longitude!)
                let annotation = MKPointAnnotation()
                annotation.coordinate = businessLocation
                //let annotationLabelString = business.name
                annotation.title = business.name
                annotation.subtitle = business.address
                mapView.addAnnotation(annotation)
            }
        }
        var zoomRect: MKMapRect = MKMapRectNull
        for annotation in mapView.annotations {
            let annotationPoint: MKMapPoint = MKMapPointForCoordinate(annotation.coordinate)
            let pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1)
            zoomRect = MKMapRectUnion(zoomRect, pointRect)
        }
        mapView.setVisibleMapRect(zoomRect, edgePadding: UIEdgeInsetsMake(0, 15, 0, 15), animated: true)
    }
    

    @IBAction func backButtonClicked(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func addAnnotationAtCoordinate(coordinate: CLLocationCoordinate2D) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
