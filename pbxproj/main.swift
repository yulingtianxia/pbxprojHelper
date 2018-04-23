//
//  main.swift
//  pbxproj
//
//  Created by 杨萧玉 on 2016/10/4.
//  Copyright © 2016年 杨萧玉. All rights reserved.
//

import Foundation

let help = "No files specified.\n" +
    "Usage: pbxproj [command_option] file\n" +
    "Command options are (-convert is the default):\n" +
    "-compare modified_file -o path          compare modified property list file with property list file and generate a json result at the given path\n" +
    "-apply json_file                        apply a json file on property list file\n" +
    "-revert                                 revert a json file on property list file\n" +
    "-recover                                recover a property list file from latest change\n" +
    "-convert                                rewrite a property list file in xml format"

if CommandLine.arguments.count == 1 {
    print(help)
}
else {
    switch CommandLine.arguments[1] {
    case "-compare":
        if CommandLine.arguments.count == 6 {
            let modifiedFile = CommandLine.arguments[2]
            let output: String
            let originalFile: String
            if CommandLine.arguments[3] == "-o" {
                output = CommandLine.arguments[4]
                originalFile = CommandLine.arguments[5]
            }
            else if CommandLine.arguments[4] == "-o" {
                output = CommandLine.arguments[5]
                originalFile = CommandLine.arguments[3]
            }
            else {
                output = ""
                originalFile = ""
                print(help)
            }
            PropertyListHandler.generateJSON(filePath: output, withModifiedProject: URL(fileURLWithPath: modifiedFile), originalProject: URL(fileURLWithPath: originalFile))
        }
        else {
            print(help)
        }
    case "-apply":
        if CommandLine.arguments.count == 4 {
            let jsonFile = CommandLine.arguments[2]
            let projectFile = CommandLine.arguments[3]
            if let jsonObject = PropertyListHandler.parseJSON(fileURL: URL(fileURLWithPath: jsonFile)) as? [String: Any],
                let projectObject = PropertyListHandler.parseProject(fileURL: URL(fileURLWithPath: projectFile)) {
                let appliedProjectObject = PropertyListHandler.apply(json: jsonObject, onProjectData: projectObject)
                PropertyListHandler.generateProject(fileURL: URL(fileURLWithPath: projectFile), withPropertyList: appliedProjectObject)
            }
        }
        else {
            print(help)
        }
    case "-revert":
        if CommandLine.arguments.count == 3 {
            let jsonFile = CommandLine.arguments[2]
            let projectFile = CommandLine.arguments[3]
            if let jsonObject = PropertyListHandler.parseJSON(fileURL: URL(fileURLWithPath: jsonFile)) as? [String: Any],
                let projectObject = PropertyListHandler.parseProject(fileURL: URL(fileURLWithPath: projectFile)) {
                let appliedProjectObject = PropertyListHandler.apply(json: jsonObject, onProjectData: projectObject, forward: false)
                PropertyListHandler.generateProject(fileURL: URL(fileURLWithPath: projectFile), withPropertyList: appliedProjectObject)
            }
        }
        else {
            print(help)
        }
    case "-recover":
        if CommandLine.arguments.count == 3 {
            let projectFile = CommandLine.arguments[2]
            if PropertyListHandler.recoverProject(fileURL: URL(fileURLWithPath: projectFile)) {
                print("recover project success!")
            }
        }
        else {
            print(help)
        }
    case "-convert":
        if CommandLine.arguments.count == 3 {
            let projectFile = CommandLine.arguments[2]
            if let projectObject = PropertyListHandler.parseProject(fileURL: URL(fileURLWithPath: projectFile)) {
                PropertyListHandler.generateProject(fileURL: URL(fileURLWithPath: projectFile), withPropertyList: projectObject)
            }
        }
    default:
        if CommandLine.arguments.count == 2 {
            let projectFile = CommandLine.arguments[1]
            if let projectObject = PropertyListHandler.parseProject(fileURL: URL(fileURLWithPath: projectFile)) {
                PropertyListHandler.generateProject(fileURL: URL(fileURLWithPath: projectFile), withPropertyList: projectObject)
            }
        }
        else {
            print(help)
        }
    }
}


