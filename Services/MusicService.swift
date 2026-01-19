//
//  MusicService.swift
//  DeskPet-QuanQuan
//
//  Created by Yixiao Chen on 1/13/26.
//

import Foundation
import AppKit

class MusicService {
    
    // 返回格式：(歌名, 歌手)
    func getCurrentTrack() -> (title: String, artist: String)? {
        // 1. 优先检查 Apple Music
        if let song = getAppleMusicTrack() {
            return song
        }
        
        // 2. 如果没开 Music，检查 Spotify
        if let song = getSpotifyTrack() {
            return song
        }
        
        return nil
    }
    
    // --- Apple Music 获取逻辑 ---
    private func getAppleMusicTrack() -> (String, String)? {
        let scriptSource = """
        if application "Music" is running then
            tell application "Music"
                if player state is playing then
                    return {name of current track, artist of current track}
                end if
            end tell
        end if
        """
        return executeScript(scriptSource)
    }
    
    // --- Spotify 获取逻辑 ---
    private func getSpotifyTrack() -> (String, String)? {
        let scriptSource = """
        if application "Spotify" is running then
            tell application "Spotify"
                if player state is playing then
                    return {name of current track, artist of current track}
                end if
            end tell
        end if
        """
        return executeScript(scriptSource)
    }
    
    // --- 执行 AppleScript 的通用方法 ---
    private func executeScript(_ source: String) -> (String, String)? {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: source) {
            let output = scriptObject.executeAndReturnError(&error)
            
            // AppleScript 返回的是一个 List {name, artist}
            if output.descriptorType != 0 {
                // 安全获取列表中的两个元素
                if output.numberOfItems >= 2 {
                    let title = output.atIndex(1)?.stringValue ?? "Unknown"
                    let artist = output.atIndex(2)?.stringValue ?? "Unknown"
                    return (title, artist)
                }
            }
        }
        return nil
    }
}
