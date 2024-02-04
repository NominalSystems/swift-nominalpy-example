# swift-nominalpy-example
An example of running a Nominal API simulation using the NominalPy Python package via Swift. This example was generated in partnership with Gilmour Space to be used with their Gilmour Operations and Testing System (GOATS) software.

# NominalPy Instalation 
NominalPy is a Python wrapper for the Nominal Systems API and can be installed via `pip install nominalpy` with documentation available [here](https://docs.nominalsys.com/v0.7/api/Python/index.html).  

# Swift Installation 
To run the provided Swift example, you must have Swift installed. There are a few ways to install Swift depending on your operating system: [swift.org](https://www.swift.org/download/), [swiftly](https://github.com/swift-server/swiftly), [swiftenv](https://github.com/kylef/swiftenv)

It is best to install the latest version as it can compile older versions of Swift.

# Python Kit 
To use Python Kit in Swift, it needs to be added as a dependency to any custom Swift Packages. The provided example already has Python Kit included as a dependency.

To learn more about Python Kit, you can find additional documentation [here](https://colab.research.google.com/github/tensorflow/swift/blob/main/docs/site/tutorials/python_interoperability.ipynb#scrollTo=Te7sNNx9c_am)  

# Final Setup 
Before executing the Swift example, your Nominal API Access Token must be stored as an Environmental Variable under the name `NOMINAL_API_KEY`. 
An optional Environmental Variable can also be configured for the absolute folder path for data export under the name `NOMINAL_API_OUTPUT_PATH`. 

To execute the provided example, navigate to the root folder of this repo via your terminal and execute `swift run`. 
