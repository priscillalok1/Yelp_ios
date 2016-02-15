//
//  BusinessesViewController.swift
//  Yelp
//
//  Created by Timothy Lee on 4/23/15.
//  Copyright (c) 2015 Timothy Lee. All rights reserved.
//

import UIKit

class BusinessesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FiltersViewControllerDelegate, UISearchBarDelegate, UIScrollViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    var businesses: [Business]!
    var filteredBusinesses: [Business]!
    var searchActive: Bool = false
    var isMoreDataLoading = false
    
    var currFilters: [String: AnyObject]?
    var currOffset: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //set up search bar
        let searchBar = UISearchBar()
        searchBar.sizeToFit()
        navigationItem.titleView = searchBar
        searchBar.placeholder = "Restaurants"
        searchBar.delegate = self

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 120
        currOffset = 0
        
        Business.searchWithTerm("Restaurants", offset: currOffset, completion: { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            self.tableView.reloadData()
            for business in businesses {
                print(business.name!)
                print(business.address!)
            }
        })

/* Example of Yelp search with more search options specified
        Business.searchWithTerm("Restaurants", sort: .Distance, categories: ["asianfusion", "burgers"], deals: true) { (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            
            for business in businesses {
                print(business.name!)
                print(business.address!)
            }
        }
*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let navigationcontroller = segue.destinationViewController as! UINavigationController
        if segue.identifier == "filtersSegue" {
            let filtersViewController = navigationcontroller.topViewController as! FiltersViewController
            filtersViewController.delegate = self
            if currFilters != nil {
                filtersViewController.filters = currFilters!
            }
        } else if segue.identifier == "mapSegue" {
            let mapViewController = navigationcontroller.topViewController as! MapViewController
            if self.businesses != nil {
                mapViewController.businesses = self.businesses
            }
            
        }
    }

    func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String : AnyObject]) {
        currFilters = filters
        let categories = filters["categories"] as? [String]
        let deals = filters["deals"] as? Bool
        let sort = YelpSortMode(rawValue: (filters["sort"]!["code"] as? Int)!)!
        let distance = filters["distance"]!["code"] as? Int
        currOffset = 0
        Business.searchWithTerm("Restaurants", sort: sort, categories: categories, deals: deals, distance: distance, offset: currOffset) {
            (businesses: [Business]!, error: NSError!) -> Void in
            self.businesses = businesses
            self.tableView.reloadData()
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if(!isMoreDataLoading) {
            // Calculate the position of one screen length before the bottom of the results
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            // When the user has scrolled past the threshold, start requesting
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.dragging) {
                isMoreDataLoading = true
                currOffset = currOffset! + self.businesses.count
                if currFilters == nil {
                    Business.searchWithTerm("Restaurants", offset: currOffset) {
                        (businesses: [Business]!, error: NSError!) -> Void in
                        self.isMoreDataLoading = false
                        if businesses.count == 0 {
                            self.currOffset = self.currOffset! - self.businesses.count
                        }
                        for business in businesses {
                            self.businesses.append(business)
                        }
                        self.tableView.reloadData()
                    }
                } else {
                    let categories = currFilters!["categories"] as? [String]
                    let deals = currFilters!["deals"] as? Bool
                    let sort = YelpSortMode(rawValue: (currFilters!["sort"]!["code"] as? Int)!)!
                    let distance = currFilters!["distance"]!["code"] as? Int
                    Business.searchWithTerm("Restaurants", sort: sort, categories: categories, deals: deals, distance: distance, offset: currOffset) {
                        (businesses: [Business]!, error: NSError!) -> Void in
                        self.isMoreDataLoading = false
                        if businesses.count == 0 {
                            self.currOffset = self.currOffset! - self.businesses.count
                        }
                        for business in businesses {
                            self.businesses.append(business)
                        }
                        self.tableView.reloadData()
                    }
                }
                
            }

        }
    }
    
    //# MARK: TableView Methods
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(searchActive) {
            return filteredBusinesses.count
        }
        if businesses != nil {
            return businesses!.count
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusinessCell", forIndexPath: indexPath) as! BusinessCell
        if(searchActive) {
            cell.business = filteredBusinesses[indexPath.row]
        } else {
            cell.business = businesses[indexPath.row]
        }
        return cell
    }

    //# MARK: Search Methods
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredBusinesses = businesses.filter({ (business) -> Bool in
            let tmp: Business = business
            let businessName: NSString = tmp.name!
            let range = businessName.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch)
            return range.location != NSNotFound
        })
        //search is not active if no search results found
        if(filteredBusinesses.count == 0){
            searchActive = false;
        } else {
            searchActive = true;
        }
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
        searchActive = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.endEditing(true)
        searchBar.text = ""
        searchActive = false
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchActive = false
    }

}
