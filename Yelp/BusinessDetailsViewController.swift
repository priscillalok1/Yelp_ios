//
//  BusinessDetailsViewController.swift
//  Yelp
//
//  Created by Priscilla Lok on 2/15/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class BusinessDetailsViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var categoriesLabel: UILabel!
    @IBOutlet weak var ratingImageView: UIImageView!
    @IBOutlet weak var reviewsCountLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var backsplashImageView: UIImageView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var detailsContainerView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager : CLLocationManager!
    
    var business: Business!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.tintColor = UIColor.whiteColor()
        nameLabel.text = business.name
        nameLabel.preferredMaxLayoutWidth = nameLabel.frame.size.width
        backsplashImageView.setImageWithURL(business.imageURL!)
        backsplashImageView.contentMode = .ScaleAspectFill
        backsplashImageView.alpha = 0.2
        categoriesLabel.text = business.categories
        reviewsCountLabel.text = "\(business.reviewCount!) Reviews"
        ratingImageView.setImageWithURL(business.ratingImageURL!)
        addressLabel.text = business.address
        distanceLabel.text = business.distance
        detailsContainerView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        
        //map view initialize
        let businessCoordinate = business.coordinate
        let longitude = businessCoordinate["longitude"]
        let latitude = businessCoordinate["latitude"]
        let businessLocation = CLLocationCoordinate2DMake(latitude!, longitude!)
        let annotation = MKPointAnnotation()
        annotation.coordinate = businessLocation
        mapView.addAnnotation(annotation)
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(businessLocation, span)
        mapView.setRegion(region, animated: false)
    
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func directionsButtonClicked(sender: AnyObject) {
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 200
//        locationManager.requestWhenInUseAuthorization()
        
        let businessCoordinate = business.coordinate
        let longitude = businessCoordinate["longitude"]
        let latitude = businessCoordinate["latitude"]
        let businessLocation = CLLocationCoordinate2DMake(latitude!, longitude!)
        let place: MKPlacemark = MKPlacemark.init(coordinate: businessLocation, addressDictionary: nil)
        let destination: MKMapItem = MKMapItem(placemark: place)
        let currentLocationMapItem: MKMapItem = MKMapItem.mapItemForCurrentLocation()
        destination.name = business.name
        let items:[MKMapItem] = [currentLocationMapItem, destination]
        let options: NSDictionary = NSDictionary(object: MKLaunchOptionsDirectionsModeDriving, forKey: MKLaunchOptionsDirectionsModeKey)
        MKMapItem.openMapsWithItems(items, launchOptions: options as? [String : AnyObject])
        

    }

    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.1, 0.1)
            let region = MKCoordinateRegionMake(location.coordinate, span)
            mapView.setRegion(region, animated: false)
        }
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
