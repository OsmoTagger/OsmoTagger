//
//  OverpasClient.swift
//  OsmoTagger
//
//  Created by Аркадий Торвальдс on 18.09.2023.
//

import Foundation

class OverpasClient: NSObject {
    weak var delegate: OverpasProtocol?
    
    var downloadCount: Int64 = 0
    
    func getData(urlStr: String) async throws {
        let str = "https://overpass-api.de/api/interpreter?data=" + urlStr
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        guard let urlStr = str.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: urlStr) else { throw "Error generate URL" }
        let request = URLRequest(url: url)
        let task = session.downloadTask(with: request)
        task.resume()
    }
}

extension OverpasClient: URLSessionDownloadDelegate {
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let data = try? Data(contentsOf: location) else { return }
        try? data.write(to: AppSettings.settings.overpasDataURL)
        delegate?.downloadCompleted(with: location)
    }
    
    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten _: Int64, totalBytesExpectedToWrite _: Int64) {
        downloadCount += bytesWritten
        delegate?.downloadProgress(downloadCount)
    }
}
