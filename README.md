# README

OpenStreetEditor is an open-source project for editing OpenStreetMap maps, utilizing the fast and powerful [GLMap framework](https://globus.software) for displaying OpenStreetMap maps.

## Resources

* Explore the [GLMap documentation](https://globus.software/docs/objc/api/latest/index.html) to familiarize yourself with its features.
* Find the OpenStreetMap API documentation [here](https://wiki.openstreetmap.org/wiki/API_v0.6).

## Installation

Follow these steps to build and run OpenStreetEditor:

1. Clone the repository.
2. Register an account on the [GLMap developer's website](https://user.getyourmap.com/) and obtain an API key to access the functionality.
3. In the [settings](https://www.openstreetmap.org/oauth2/applications) of your personal account, register a new OAuth 2.0 application. Specify an unoccupied URI, for example, "myOpenStreetMapEditor", and save the received client ID and client secret. OpenStreetEditor allows you to work on a test server, so if you want to use it, register the same application in your [personal account](https://master.apis.dev.openstreetmap.org/oauth2/applications) on the test server (the accounts of the working and test server are not linked, you will need to register a new account). Don't forget that there is no data on the test server by default. You can upload data to the region you need using a simple [Python script](https://github.com/Zverik/osm_to_sandbox).
4. Specify your URI in the OsmClient class in the authorization methods.
5. Create a new ApiKeys.swift file and put it in the repository. This file has been added to .gitignore and will not be made publicly available. Create a structure in it:

```
    struct ApiKeys {
        static let prodClienID = "YOUR_CLIENTID_FROM_PRODUCTION_SERVER"
        static let prodClientSecret = "YOUR_CLIENT_SECRET_FROM_PRODUCTION_SERVER"
        static let devClientID = "YOUR_CLIENTID_FROM_TEST_SERVER" // if don't use, set ""
        static let devClientSecret = "YOUR_CLIENT_SECRET_FROM_TEST_SERVER" // if don't use, set ""
        static let glAPIKey = "YOUR_API_KEY"
    }
```

## Discussion and help

* You can ask all questions and suggestions in the OpenStreetEditor [telegram chat](https://t.me/OpenStreetEditor_chat).
* You can follow the news in the [telegram channel](https://t.me/OpenStreetEditor).
