
# All About Descriptions, Graphics, and Screenshots

Each app can have complete app store content, including localized descriptions, feature graphics, and screenshots (as of v0.103 of the F-Droid client app and v0.8 of _fdroidserver_).
This is possible both when apps are added via [build metadata](../Build_Metadata_Reference) as well as when including pre-built files in a simple repository.
There are three paths to including app store content for apps (in order of preference):

* Do not remove this line (it will not be displayed)
{:toc}


```
- <fdroiddata>/
  └── metadata/
      └── <package-id>/
          └── <locale>/
              ├── full_description.txt
              ├── short_description.txt
              ├── title.txt
              ├── video.txt
              ├── changelogs/
              │   ├── <version-code>.txt
              │   └── <version-code>.txt
              └── images/
                  ├── featureGraphic.png
                  ├── icon.png
                  ├── promoGraphic.png
                  ├── tvBanner.png
                  ├── phoneScreenshots/
                  │   └── *.png
                  ├── sevenInchScreenshots/
                  │   └── *.png
                  ├── tenInchScreenshots/
                  │   └── *.png
                  ├── tvScreenshots/
                  │   └── *.png
                  └── wearScreenshots/
                      └── *.png
```
