//
//  FiltersViewController.swift
//  Yelp
//
//  Created by Priscilla Lok on 2/10/16.
//  Copyright © 2016 Timothy Lee. All rights reserved.
//

import UIKit

@objc protocol FiltersViewControllerDelegate {
    optional func filtersViewController(filtersViewController: FiltersViewController, didUpdateFilters filters: [String:AnyObject])
}

enum filterTypes : Int {
    case Deals = 0
    case SortBy
    case Distance
    case Categories
    case Unknown
}

class FiltersViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    weak var delegate: FiltersViewControllerDelegate?

    var shouldIncludeDeals: Bool! = false
    var sortByOptions: [[String:AnyObject]]! // dict of {string: int, string: int ...}
    var currSortByFilter: Int!
    var distanceOptions: [[String:AnyObject]]!
    var currMaxDistance: Int!
    var categoryOptions: [[String:String]]!
    var categorySwitchStates = [Int:Bool]()
    
    var filters = [String:AnyObject]()
//    var testSwitchIsToggled: Bool! = false
    
    var isExpanded = [Bool]() //keeps array of if each section is expanded or not
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.sectionHeaderHeight = 50
        
        initFilterTypes()
        self.isExpanded = [false, false, false, false]
        
        currSortByFilter = (filters["sort"] == nil ? 0 : filters["sort"]!["code"] as? Int)
        if(filters["distance"] != nil) {
            let currDistanceOptionCode = filters["distance"]!["code"] as! Int
            let index = distanceOptions.indexOf ({ $0["code"] as! Int == currDistanceOptionCode })
            currMaxDistance = index
        } else {
            currMaxDistance = 0
        }
        shouldIncludeDeals = (filters["deals"] == nil ? false : filters["deals"] as? Bool)
        
        tableView.delegate = self
        tableView.dataSource = self
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onCancelButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func onSearchButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
        let filteredCategories = searchCategories(categorySwitchStates)
        filters["categories"] = filteredCategories
        filters["deals"] = shouldIncludeDeals
        filters["sort"] = sortByOptions[currSortByFilter]
        filters["distance"] = distanceOptions[currMaxDistance]
        delegate?.filtersViewController?(self, didUpdateFilters: filters)
    }

    
    //MARK: - table functions
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let tempView: UIView = UIView(frame: CGRectMake(0,200,300,244))
        tempView.backgroundColor = UIColor(red: 0.9294, green: 0.9294, blue: 0.9294, alpha: 1.0)
        
        let tempLabel: UILabel = UILabel(frame: CGRectMake(15, 5, 300, 44))
        tempLabel.backgroundColor = UIColor.clearColor()
        tempLabel.textColor = UIColor.darkGrayColor()
        tempLabel.font = UIFont (name: "Helvetica Neue", size: 16)
        let filterType: filterTypes = filterTypeFromIndex(section)
        switch(filterType) {
        case .Deals:
            tempLabel.text = "DEALS"
        case .SortBy:
            tempLabel.text = "SORT BY"
        case .Distance:
            tempLabel.text = "DISTANCE"
        case .Categories:
            tempLabel.text =  "CATEGORIES"
        case .Unknown:
            tempLabel.text = ""
        }

        tempView.addSubview(tempLabel)
        return tempView
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let filterType: filterTypes = filterTypeFromIndex(section)
        switch(filterType) {
        case .Deals:
            return 1
        case .SortBy:
            if isExpanded[1] == true {
                return sortByOptions.count
            } else {
                return 1
            }
        case .Distance:
            if isExpanded [2] == true {
                return distanceOptions.count
            } else {
                return 1
            }
        case .Categories:
            if isExpanded [3] == true {
                return categoryOptions.count
            } else {
                return 6
            }
        case .Unknown:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let filterType: filterTypes = filterTypeFromIndex(indexPath.section)
        switch(filterType) {
        case .Deals:
            let cell =  tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! SwitchCell
            cell.switchLabel.text = "Offering a Deal"
            cell.delegate = self
            cell.onSwitch.on = shouldIncludeDeals
            return cell
        case .SortBy:
            let cell = tableView.dequeueReusableCellWithIdentifier("ChoiceCell", forIndexPath: indexPath) as! ChoiceCell
            if !isExpanded[1] {
                cell.choiceLabel.text = sortByOptions[currSortByFilter]["name"] as? String
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.choiceLabel.text = sortByOptions[indexPath.row]["name"] as? String
                cell.accessoryType = (indexPath.row == currSortByFilter ?
                    UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None)
            }
            return cell
        case .Distance:
            let cell = tableView.dequeueReusableCellWithIdentifier("ChoiceCell", forIndexPath: indexPath) as! ChoiceCell
            if !isExpanded[2] {
                cell.choiceLabel.text = distanceOptions[currMaxDistance]["name"] as? String
                cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            } else {
                cell.choiceLabel.text = distanceOptions[indexPath.row]["name"] as? String
                cell.accessoryType = (indexPath.row == currMaxDistance ?
                    UITableViewCellAccessoryType.Checkmark : UITableViewCellAccessoryType.None)
            }
            return cell
        case .Categories:
            let cell = tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! SwitchCell
            if !isExpanded[3] && indexPath.row == 5 {
                cell.switchLabel.text = "Show More..."
                cell.onSwitch.hidden = true
            } else {
                cell.switchLabel.text = categoryOptions[indexPath.row]["name"]
                cell.delegate = self
                cell.onSwitch.on = categorySwitchStates[indexPath.row] ?? false
                cell.onSwitch.hidden = false
            }
            return cell
        case .Unknown:
            return tableView.dequeueReusableCellWithIdentifier("SwitchCell", forIndexPath: indexPath) as! SwitchCell
        }
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let filterType: filterTypes = filterTypeFromIndex(indexPath.section)
        switch(filterType) {
        case .Deals:
            return
        case .SortBy:
            if isExpanded[1] {
                if indexPath.row != currSortByFilter {
                    currSortByFilter = indexPath.row
                }
                isExpanded [1] = false
            } else {
                isExpanded [1] = true
            }
            tableView.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Fade)
            
        case .Distance:
            if isExpanded[2] {
                if indexPath.row != currMaxDistance{
                    currMaxDistance = indexPath.row
                }
                isExpanded [2] = false
            } else {
                isExpanded [2] = true
            }
            tableView.reloadSections(NSIndexSet(index: 2), withRowAnimation: UITableViewRowAnimation.Fade)
        case .Categories:
            if !isExpanded [3] && indexPath.row == 5 {
                isExpanded [3] = true
            }
            tableView.reloadSections(NSIndexSet(index: 3), withRowAnimation: UITableViewRowAnimation.Fade)
        case .Unknown:
            return
        }
    }
    
    //MARK: - private methods
    
    func filterTypeFromIndex (index: Int) -> filterTypes {
        switch (index) {
        case 0:
            return filterTypes.Deals
        case 1:
            return filterTypes.SortBy
        case 2:
            return filterTypes.Distance
        case 3:
            return filterTypes.Categories
        default:
            return filterTypes.Unknown
        }
    }
    
    func searchCategories (switchStates: [Int:Bool]) -> [String]{
        var selectedCategories = [String]()
        for (row,isSelected) in switchStates {
            if isSelected {
                selectedCategories.append(categoryOptions[row]["code"]!)
            }
        }
        return selectedCategories
    }
    
    //MARK: - categories
    func initFilterTypes() {
        sortByOptions = [
            ["name": "Best Matched", "code":YelpSortMode.BestMatched.rawValue],
            ["name": "Distance", "code":YelpSortMode.Distance.rawValue],
            ["name": "Highest Rated", "code":YelpSortMode.HighestRated.rawValue]
        ]
        distanceOptions = [
            ["name": "0.3 mi","code":483],
            ["name": "1 mi", "code":1609],
            ["name": "5 mi", "code":8046],
            ["name": "20 mi", "code":32186]
        ]
        categoryOptions = [["name" : "Afghan", "code": "afghani"],
            ["name" : "African", "code": "african"],
            ["name" : "American, New", "code": "newamerican"],
            ["name" : "American, Traditional", "code": "tradamerican"],
            ["name" : "Arabian", "code": "arabian"],
            ["name" : "Argentine", "code": "argentine"],
            ["name" : "Armenian", "code": "armenian"],
            ["name" : "Asian Fusion", "code": "asianfusion"],
            ["name" : "Asturian", "code": "asturian"],
            ["name" : "Australian", "code": "australian"],
            ["name" : "Austrian", "code": "austrian"],
            ["name" : "Baguettes", "code": "baguettes"],
            ["name" : "Bangladeshi", "code": "bangladeshi"],
            ["name" : "Barbeque", "code": "bbq"],
            ["name" : "Basque", "code": "basque"],
            ["name" : "Bavarian", "code": "bavarian"],
            ["name" : "Beer Garden", "code": "beergarden"],
            ["name" : "Beer Hall", "code": "beerhall"],
            ["name" : "Beisl", "code": "beisl"],
            ["name" : "Belgian", "code": "belgian"],
            ["name" : "Bistros", "code": "bistros"],
            ["name" : "Black Sea", "code": "blacksea"],
            ["name" : "Brasseries", "code": "brasseries"],
            ["name" : "Brazilian", "code": "brazilian"],
            ["name" : "Breakfast & Brunch", "code": "breakfast_brunch"],
            ["name" : "British", "code": "british"],
            ["name" : "Buffets", "code": "buffets"],
            ["name" : "Bulgarian", "code": "bulgarian"],
            ["name" : "Burgers", "code": "burgers"],
            ["name" : "Burmese", "code": "burmese"],
            ["name" : "Cafes", "code": "cafes"],
            ["name" : "Cafeteria", "code": "cafeteria"],
            ["name" : "Cajun/Creole", "code": "cajun"],
            ["name" : "Cambodian", "code": "cambodian"],
            ["name" : "Canadian", "code": "New)"],
            ["name" : "Canteen", "code": "canteen"],
            ["name" : "Caribbean", "code": "caribbean"],
            ["name" : "Catalan", "code": "catalan"],
            ["name" : "Chech", "code": "chech"],
            ["name" : "Cheesesteaks", "code": "cheesesteaks"],
            ["name" : "Chicken Shop", "code": "chickenshop"],
            ["name" : "Chicken Wings", "code": "chicken_wings"],
            ["name" : "Chilean", "code": "chilean"],
            ["name" : "Chinese", "code": "chinese"],
            ["name" : "Comfort Food", "code": "comfortfood"],
            ["name" : "Corsican", "code": "corsican"],
            ["name" : "Creperies", "code": "creperies"],
            ["name" : "Cuban", "code": "cuban"],
            ["name" : "Curry Sausage", "code": "currysausage"],
            ["name" : "Cypriot", "code": "cypriot"],
            ["name" : "Czech", "code": "czech"],
            ["name" : "Czech/Slovakian", "code": "czechslovakian"],
            ["name" : "Danish", "code": "danish"],
            ["name" : "Delis", "code": "delis"],
            ["name" : "Diners", "code": "diners"],
            ["name" : "Dumplings", "code": "dumplings"],
            ["name" : "Eastern European", "code": "eastern_european"],
            ["name" : "Ethiopian", "code": "ethiopian"],
            ["name" : "Fast Food", "code": "hotdogs"],
            ["name" : "Filipino", "code": "filipino"],
            ["name" : "Fish & Chips", "code": "fishnchips"],
            ["name" : "Fondue", "code": "fondue"],
            ["name" : "Food Court", "code": "food_court"],
            ["name" : "Food Stands", "code": "foodstands"],
            ["name" : "French", "code": "french"],
            ["name" : "French Southwest", "code": "sud_ouest"],
            ["name" : "Galician", "code": "galician"],
            ["name" : "Gastropubs", "code": "gastropubs"],
            ["name" : "Georgian", "code": "georgian"],
            ["name" : "German", "code": "german"],
            ["name" : "Giblets", "code": "giblets"],
            ["name" : "Gluten-Free", "code": "gluten_free"],
            ["name" : "Greek", "code": "greek"],
            ["name" : "Halal", "code": "halal"],
            ["name" : "Hawaiian", "code": "hawaiian"],
            ["name" : "Heuriger", "code": "heuriger"],
            ["name" : "Himalayan/Nepalese", "code": "himalayan"],
            ["name" : "Hong Kong Style Cafe", "code": "hkcafe"],
            ["name" : "Hot Dogs", "code": "hotdog"],
            ["name" : "Hot Pot", "code": "hotpot"],
            ["name" : "Hungarian", "code": "hungarian"],
            ["name" : "Iberian", "code": "iberian"],
            ["name" : "Indian", "code": "indpak"],
            ["name" : "Indonesian", "code": "indonesian"],
            ["name" : "International", "code": "international"],
            ["name" : "Irish", "code": "irish"],
            ["name" : "Island Pub", "code": "island_pub"],
            ["name" : "Israeli", "code": "israeli"],
            ["name" : "Italian", "code": "italian"],
            ["name" : "Japanese", "code": "japanese"],
            ["name" : "Jewish", "code": "jewish"],
            ["name" : "Kebab", "code": "kebab"],
            ["name" : "Korean", "code": "korean"],
            ["name" : "Kosher", "code": "kosher"],
            ["name" : "Kurdish", "code": "kurdish"],
            ["name" : "Laos", "code": "laos"],
            ["name" : "Laotian", "code": "laotian"],
            ["name" : "Latin American", "code": "latin"],
            ["name" : "Live/Raw Food", "code": "raw_food"],
            ["name" : "Lyonnais", "code": "lyonnais"],
            ["name" : "Malaysian", "code": "malaysian"],
            ["name" : "Meatballs", "code": "meatballs"],
            ["name" : "Mediterranean", "code": "mediterranean"],
            ["name" : "Mexican", "code": "mexican"],
            ["name" : "Middle Eastern", "code": "mideastern"],
            ["name" : "Milk Bars", "code": "milkbars"],
            ["name" : "Modern Australian", "code": "modern_australian"],
            ["name" : "Modern European", "code": "modern_european"],
            ["name" : "Mongolian", "code": "mongolian"],
            ["name" : "Moroccan", "code": "moroccan"],
            ["name" : "New Zealand", "code": "newzealand"],
            ["name" : "Night Food", "code": "nightfood"],
            ["name" : "Norcinerie", "code": "norcinerie"],
            ["name" : "Open Sandwiches", "code": "opensandwiches"],
            ["name" : "Oriental", "code": "oriental"],
            ["name" : "Pakistani", "code": "pakistani"],
            ["name" : "Parent Cafes", "code": "eltern_cafes"],
            ["name" : "Parma", "code": "parma"],
            ["name" : "Persian/Iranian", "code": "persian"],
            ["name" : "Peruvian", "code": "peruvian"],
            ["name" : "Pita", "code": "pita"],
            ["name" : "Pizza", "code": "pizza"],
            ["name" : "Polish", "code": "polish"],
            ["name" : "Portuguese", "code": "portuguese"],
            ["name" : "Potatoes", "code": "potatoes"],
            ["name" : "Poutineries", "code": "poutineries"],
            ["name" : "Pub Food", "code": "pubfood"],
            ["name" : "Rice", "code": "riceshop"],
            ["name" : "Romanian", "code": "romanian"],
            ["name" : "Rotisserie Chicken", "code": "rotisserie_chicken"],
            ["name" : "Rumanian", "code": "rumanian"],
            ["name" : "Russian", "code": "russian"],
            ["name" : "Salad", "code": "salad"],
            ["name" : "Sandwiches", "code": "sandwiches"],
            ["name" : "Scandinavian", "code": "scandinavian"],
            ["name" : "Scottish", "code": "scottish"],
            ["name" : "Seafood", "code": "seafood"],
            ["name" : "Serbo Croatian", "code": "serbocroatian"],
            ["name" : "Signature Cuisine", "code": "signature_cuisine"],
            ["name" : "Singaporean", "code": "singaporean"],
            ["name" : "Slovakian", "code": "slovakian"],
            ["name" : "Soul Food", "code": "soulfood"],
            ["name" : "Soup", "code": "soup"],
            ["name" : "Southern", "code": "southern"],
            ["name" : "Spanish", "code": "spanish"],
            ["name" : "Steakhouses", "code": "steak"],
            ["name" : "Sushi Bars", "code": "sushi"],
            ["name" : "Swabian", "code": "swabian"],
            ["name" : "Swedish", "code": "swedish"],
            ["name" : "Swiss Food", "code": "swissfood"],
            ["name" : "Tabernas", "code": "tabernas"],
            ["name" : "Taiwanese", "code": "taiwanese"],
            ["name" : "Tapas Bars", "code": "tapas"],
            ["name" : "Tapas/Small Plates", "code": "tapasmallplates"],
            ["name" : "Tex-Mex", "code": "tex-mex"],
            ["name" : "Thai", "code": "thai"],
            ["name" : "Traditional Norwegian", "code": "norwegian"],
            ["name" : "Traditional Swedish", "code": "traditional_swedish"],
            ["name" : "Trattorie", "code": "trattorie"],
            ["name" : "Turkish", "code": "turkish"],
            ["name" : "Ukrainian", "code": "ukrainian"],
            ["name" : "Uzbek", "code": "uzbek"],
            ["name" : "Vegan", "code": "vegan"],
            ["name" : "Vegetarian", "code": "vegetarian"],
            ["name" : "Venison", "code": "venison"],
            ["name" : "Vietnamese", "code": "vietnamese"],
            ["name" : "Wok", "code": "wok"],
            ["name" : "Wraps", "code": "wraps"],
            ["name" : "Yugoslav", "code": "yugoslav"]]
    }
    
}

extension FiltersViewController: SwitchCellDelegate  {
    func switchCell(switchCell: SwitchCell, didChangeValue value: Bool) {
        let indexPath = tableView.indexPathForCell(switchCell)!
        let filterType: filterTypes = filterTypeFromIndex(indexPath.section)
        
        switch(filterType) {
        case .Deals:
            shouldIncludeDeals = value
        case .SortBy:
            return
        case .Distance:
            return
        case .Categories:
            categorySwitchStates[indexPath.row] = value
        case .Unknown:
            return
        }
       // print(searchCategories(categorySwitchStates))
    }
}

