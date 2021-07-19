//
//  ViewController.swift
//  TrackingApp
//
//  Created by S, Aswin (623-Extern) on 22/05/21.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var startTracking: UIButton!
    @IBOutlet weak var stopTracking: UIButton!
    private var locationManager: CLLocationManager?
    private var startTime: Date?
    var timer:  Timer?
    var locationArray: [CLLocation] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.activityType = . automotiveNavigation
        locationManager?.distanceFilter = 100
        
        // Do any additional setup after loading the view.
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("authorized")
        case .denied, .restricted :
            let alert = UIAlertController(title: "Alert", message: "TrackingApp don't have the permission to access your location", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                switch action.style{
                case .default:
                    print("default")
                default:
                    break
                }
            }))
            self.present(alert, animated: true, completion: nil)
        default:
            break;
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        postTest(locationData: location)
    }
    @IBAction func startTrackingAction(_ sender: Any) {
            switch locationManager?.authorizationStatus {
                case .restricted, .denied:
                    let alert = UIAlertController(title: "Alert", message: "TrackingApp don't have the permission to access your location. Provide location permission in the settings", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
                        switch action.style{
                        case .cancel:
                            print("cancel")
                        default:
                            break
                        }
                    }))
                    self.present(alert, animated: true, completion: nil)
            case .notDetermined:
                locationManager?.requestAlwaysAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager?.startUpdatingLocation()
                timer = Timer.scheduledTimer(timeInterval: 120.0, target: self, selector: #selector(self.updateLocation), userInfo: nil, repeats: true)
            default:
                break
            }
        
    }
    @IBAction func stopTrackingAction(_ sender: Any) {
        locationManager?.stopUpdatingLocation()
        timer?.invalidate()
    }
    
    @objc func updateLocation() {
        if let startTime = startTime {
            let elapsed = Date.timeIntervalSinceReferenceDate - startTime.timeIntervalSinceReferenceDate // Calculating time interval
            if elapsed > 120 { //If time interval is more than 120 seconds
                locationManager?.stopUpdatingLocation()
                locationManager?.startUpdatingLocation()
            }
        }
    }
    
    func postTest(locationData: CLLocation) {
        let session = URLSession.shared
        let url = URL(string:"www.url.com")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // If authorization is there add basic auth
        let username = "test"
        let password = "password"
        let loginString = String(format: "%@:%@", username, password)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")
        locationArray.append(locationData)
        startTime = locationData.timestamp
        print("array after adding location", locationArray)
        locationArray.forEach { (location) in
            let json = [
                "lat": location.coordinate.latitude,
                "lng": location.coordinate.longitude
            ]
            let jsonData = try! JSONSerialization.data(withJSONObject: json, options: [])
            let task = session.uploadTask(with: request, from: jsonData) { data, response, error in
                if let httpResponse = response as? HTTPURLResponse {
                    // if response is success execute the following code
                    self.locationArray.removeAll { (loc) -> Bool in
                        location.timestamp == loc.timestamp
                    }
                    print("array after removing location", self.locationArray)
                }
            }
            task.resume()
        }
    }
}
