import Foundation

/// handling Error occures in this api.
enum ServiceError: Error {
    case apiError
    case invalidEndpoint
    case invalidStatusCode
    case noData
}

extension ServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .apiError: return "something went wrong , please try again later."
        case .invalidEndpoint: return "invalid end point , please check the url."
        case .invalidStatusCode: return "invlaid status code, if you need to handle some status codes so this is you best chance."
        case .noData: return "no data found, please try again later."
        }
    }
}

class RequestHandler {
    
    /// connect to google.com
    func connect(_ value: String, completion: @escaping (Result<String, ServiceError>) -> Void ){
        print("call request number : \(value)")
        
        var _url: URL?{
            var component = URLComponents()
            component.scheme = "https"
            component.host = "google.com"
            return component.url
        }
        guard let url = _url else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            print("finishing request number : \(value)")
            if let _ = error {
                completion(.failure(.apiError))
                return
            }
            guard let _ = data else {
                completion(.failure(.noData))
                return
            }
            
            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                completion(.failure(.invalidStatusCode))
                return
            }
            
            completion(.success(value))
            }.resume()
    }
}

/// Loop over asynchronous API and then trigger if they are finished to handle it in synchronous way
func callConnect(){
    let dispatchGroup = DispatchGroup()
    
    for i in 0 ..< 4 {
        let requester = RequestHandler()
        dispatchGroup.enter()
        requester.connect("\(i)") { (result) in
            switch result {
            case .failure(_): break
            case .success(_): break
            }
            
            dispatchGroup.leave()
        }
    }
    
    dispatchGroup.notify(queue: .main) {
        print("All asynchronous API are handled in synchronous way :).\n")
        print("*******************************")
        print("now we will call the other way")
        print("*******************************\n")
        callConnectInAnotherWay()
    }
}

/// Loop over API in synchronous way.
func callConnectInAnotherWay(){
    let semaphore = DispatchSemaphore(value: 0)
    
    let dispatchQueue = DispatchQueue.global(qos: .background)
    dispatchQueue.async {
        for i in 0 ..< 4 {
            let requester = RequestHandler()
            requester.connect("\(i)") { (result) in
                switch result {
                case .failure(_): break
                case .success(_): break
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
        
        print("All requests are handled in synchronous way :). \n")
    }
}

print("*******************************")
callConnect()
