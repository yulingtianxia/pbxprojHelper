![](https://github.com/yulingtianxia/pbxprojHelper/blob/master/images/appIcon.png)

[![Language](https://img.shields.io/badge/language-Swift%204.0-orange.svg)](https://swift.org)
[![Build Status](https://travis-ci.org/yulingtianxia/pbxprojHelper.svg?branch=master)](https://travis-ci.org/yulingtianxia/pbxprojHelper)

# pbxprojHelper 

pbxprojHelper is a GUI tool developed with Cocoa and Swift 4 for parsing and changing Xcode projects configuration. You can also use `pbxproj` as a command line tool in terminal.

![Main Window](https://github.com/yulingtianxia/pbxprojHelper/blob/master/images/MainWindow@2x.png)

## Languages

[中文](Documentation/README_ZH.md)

## Articles

[pbxprojHelper--Xcode工程文件助手](http://yulingtianxia.com/blog/2016/11/28/pbxprojHelper/)

[Let's Talk About project.pbxproj](http://yulingtianxia.com/blog/2016/09/28/Let-s-Talk-About-project-pbxproj/)

## Installing pbxprojHelper

### GitHub

You can clone the [source code](https://github.com/yulingtianxia/pbxprojHelper/) of pbxprojHelper, then compile and run it by Xcode.

You can also download pbxprojHelper.app and pbxproj tool with its latest [Releases](https://github.com/yulingtianxia/pbxprojHelper/releases) on GitHub.

### App Store

Mac App Store link: (Only pbxprojHelper.app)

https://itunes.apple.com/cn/app/pbxprojhelper/id1160801848

### [Swift package manager](https://swift.org/package-manager)

Add `.Package(url: "https://github.com/yulingtianxia/pbxprojHelper.git", majorVersion: 1)` to `dependencies` in your `Package.swift`.

## Quickstart

### Use pbxprojHelper (Native Cocoa UI App)

1. Choose your project file by clicking "Select" button. Both `.xcodeproj` and `.pbxproj` file extensions are supported. The path of project file you selected will be displayed on the text field. The outline view shows data of project file.
2. Choose configuration file by clicking "Choose JSON File". Configuration file contains changes you want to make to your project. You can create a configuration file with json format, or generate it using "JSON Configuration Generator" tool provided by pbxprojHelper. The outline view will refresh data after you choose a json file.
3. Clicking "Apply" button will write changes made by json configuration to project file you selected.
4. "Revert" button does a reverse operation of "Apply" button.

### Use pbxproj (Command Line Tool)

You should move pbxproj to `/usr/local/bin/`, so you can execute `pbxproj` command conveniently in terminal.

Here is the Usage:

```
Usage: pbxproj [command_option] file
Command options are (-convert is the default):
-compare modified_file -o path          compare modified property list file with property list file and generate a json result at the given path
-apply json_file                        apply a json file on property list file
-revert                                 a json file on property list file
-recover                                recover a property list file from latest change
-convert                                rewrite a property list file in xml format
```

## Outline View

The outline view shows entire data of project.pbxproj file. You can expand an item if it's type is collection(dictionary or array). For example, the value for key `objects` is an dictionary which contains 34 key-value pairs. You can expand `objects` to view its content. For key-value pairs of dictionary, the 1st/2nd column means "Key"/"Value". If the value is a collection(not String or Number.ect), the 2nd column shows a description of the collection; For elements of array, the 1st column means "Element", but the 2nd column contains nothing.

**You can copy the text in outline view by just a click on the text. If you want to copy the whole keypath from root node, double click it.**

## Filter

You can filt the content of outline view by typing a string in the "Filter" Text Field. It's not case sensitive.

## Project File Path

There is a pull-down menu which shows five latest used file paths when you click the path of your project file. So you can choose your project files in common use quickly.

## JSON Configuration File

### Configuration Rules

The configuration file contains a list of rules. Here is an example of configuration: 

```
{
  "insert" : {
    "objects.A45A665D1D98286400DBED04.children" : [
      "a",
      "b",
      "c"
    ],
    "classes" : {
      "xixihaha": 5,
      "aaaaa" : "养小鱼"
    }
  },
  "remove" : {
    "objects.A45A666D1D98286400DBED04.buildSettings" : [
      "ALWAYS_SEARCH_USER_PATHS"
    ]
  },
  "modify" : {
    "archiveVersion" : "2"
  }
}
```

The root object must be a dictionary with 3 key-value pairs. You can "insert", "remove" and "modify" values through their key paths in project.pbxproj file. 

There are two series of configuration rules in the newest configuration file: "forward" and "backward". They respectively corresponded to "Apply" and "Revert" Functions.

#### Insert

The example above inserts 3 elements(`"a"`,`"b"`,`"c"`) into the `children` array. Note that the keypath `"objects.A45A665D1D98286400DBED04.children"` must be valid. The value of `"children"` should be an array and the value of `"classes"` should be a dictionary. **In a word, the type of incremental data should be same with original data in project.pbxproj file.**

#### Remove

The example above removes a key-value pair whose key equals `"ALWAYS_SEARCH_USER_PATHS"` from a dictionary named `buildSettings`. **The value of keypath should always be an array.** This array contains keys/elements you want to removed from dictionary/array.

#### Modify

Modify the value of keypath, so easy.

### Configuration Generator

Programmer is lazy. I can't stand wasting my time on writing json files, so I create the powerful tool called "JSON Configuration Generator":

![JSON Configuration Generator Window](https://github.com/yulingtianxia/pbxprojHelper/blob/master/images/GeneratorWindow@2x.png)

**There are two ways to open the "Generator" window:**

1. Menu -> Window -> JSON Configuration Generator
2. Key Equivament: ⇧⌘0

You can use it in an oversimplified and crude way. Just select two project files and json save path, then click the "Generate" button, and you will get a json file containing changes between modified and original project file.

Conversely, you can use this json file when you want to apply these changes to certain project file again. Please take care of this json file.

## Backups

Each time you click "Apply" button on main window, pbxprojHelper will use original or last modified project file to create backup file with "backup" extension in "Documents" folder of sandbox first, and then apply changes on project file.

~~"Revert" button uses these backups to revert project file to the latest version.~~

## Encoding

When generating project.pbxproj file with xml format, chinese characters will be translated to Unicode mathematical symbols. For example, `"杨萧玉"` in OpenStep style file will be converted to `<string>&#26472;&#33831;&#29577;</string>` in XML style. This is because Xcode will encode XML content(regarded as ASCII encoding) into Unicode again when convert XML project file to OpenStep project file.

## LICENSE

These works are available under the GNU General Public License. See the [LICENSE](LICENSE) file for more info.
