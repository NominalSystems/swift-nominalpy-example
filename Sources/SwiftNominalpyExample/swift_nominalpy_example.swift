    /*
                    [ NOMINAL SYSTEMS ]
    This code is developed by Nominal Systems to aid with communication
    to the public API. All code is under the the license provided along
    with the 'nominalpy' module. Copyright Nominal Systems, 2024.

    This example shows how the NominalPy module can be accessed in
    Swift Via PythonKit.

    The scenario is of a spacecraft with a solar panel and a
    sun pointing ADCS system that orients the spacecraft to face
    its solar panel towards the sun, using a flight software chain.
    The solar panel power and pointing error are exported as text files.
    */

    import Foundation
    import PythonKit

    public struct SwiftNominalpyExample {

    public static func run()
    {
        // Import Required NominalPy Modules
        let nominalpyModule = Python.import("nominalpy")
        let credentialsModule = Python.import("nominalpy.connection.credentials")
        let simulationModule = Python.import("nominalpy.objects.simulation")
        let astroModule = Python.import("nominalpy.maths.astro")

        // Import Required Python Modules
        let datetimeModule = Python.import("datetime")
        let numpyModule = Python.import("numpy")
        let jsonModule = Python.import("json")
        let builtinsModule = Python.import("builtins")

        //Simulation Parameters
        let tickSize=0.05
        let tickIterations=2000
        let dataSampleRate=5.0

        // Set up the API access
        let url = "https://api.nominalsys.com"
        let port = Python.None

        if let apiKey = ProcessInfo.processInfo.environment["NOMINAL_API_KEY"]
        {
            print("Nominal API Key Imported")

            // Connect to the Nominal API
            let auth: PythonObject = credentialsModule.Credentials(url,port,apiKey)
            let sim: PythonObject = simulationModule.Simulation(auth)
            print("Connected to Nominal API")

            print("Configuring the Simulation")
            //Configure the Universe with an epoch
            let types = nominalpyModule.types
            let universe = sim.get_system(types.UNIVERSE, Epoch: datetimeModule.datetime(2022, 1, 1))

            //Compute the orbit from the Keplerian elements to a state vector of (position, velocity)
            let orbit: PythonObject = astroModule.classical_to_vector_elements(6671, inclination: 35, true_anomaly: 16)

            //Add the spacecraft
            let spacecraft: PythonObject = sim.add_component(types.SPACECRAFT,
                TotalMass: 750.0,
                TotalCenterOfMass: numpyModule.array([0, 0, 0]),
                TotalCenterOfMassB_B: numpyModule.array([[900, 0, 0], [0, 800, 0], [0, 0, 600]]),
                Position: orbit[0],
                Velocity: orbit[1],
                AttitudeRate: numpyModule.array([0.2, 0.1, 0.05]))

            //Add reaction wheels
            let reactionWheels: PythonObject = sim.add_component("ReactionWheelArray",spacecraft)

            let rw1: PythonObject = sim.add_component("ReactionWheel",reactionWheels,WheelSpinAxis_B:numpyModule.array([1,0,0]))
            let rw2: PythonObject = sim.add_component("ReactionWheel",reactionWheels,WheelSpinAxis_B:numpyModule.array([0,1,0]))
            let rw3: PythonObject = sim.add_component("ReactionWheel",reactionWheels,WheelSpinAxis_B:numpyModule.array([0,0,1]))

            //Add a simple Navigator
            let navigator: PythonObject = sim.add_component("SimpleNavigator",spacecraft)

            //Add a Solar Panel
            let solarPanel: PythonObject = sim.add_component("SolarPanel",spacecraft,Area:0.01,Efficiency:0.23)

            //Add in Sun Safe Pointing
            let sunPointFsw: PythonObject = sim.add_component("SunSafePointingSoftware",spacecraft,
                MinUnitMag:0.001,
                SmallAngle:0.001,
                SunBodyVector:solarPanel.get_value("LocalUp"),
                Omega_RN_B:numpyModule.array([0,0,0]),
                SunAxisSpinRate:0.0,
                In_NavAttMsg:navigator.get_value("Out_NavAttMsg"),
                In_SunDirectionMsg:navigator.get_value("Out_NavAttMsg"))

            //Add in the MRP feedback software
            let mrpFeedbackFsw: PythonObject = sim.add_component("MRPFeedbackSoftware", spacecraft,
                K:3.5,
                P:30.0,
                Ki:-1.0,
                IntegralLimit:-20,
                In_RWSpeedMsg:reactionWheels.get_value("Out_RWSpeedMsg"),
                In_RWArrayConfigMsg:reactionWheels.get_value("Out_RWArrayConfigMsg"),
                In_AttGuidMsg:sunPointFsw.get_value("Out_AttGuidMsg"),
                In_VehicleConfigMsg:spacecraft.get_value("Out_VehicleConfigMsg"))

            //Add in the motor torque software
            let motorTorqueFsw: PythonObject = sim.add_component("ReactionWheelMotorTorqueSoftware",spacecraft,
                In_CmdTorqueBodyMsg:mrpFeedbackFsw.get_value("Out_CmdTorqueBodyMsg"),
                In_RWArrayConfigMsg:reactionWheels.get_value("Out_RWArrayConfigMsg"))

            //Connect up to the reaction wheels
            reactionWheels.set_value("In_ArrayMotorTorqueMsg", motorTorqueFsw.get_value("Out_ArrayMotorTorqueMsg"))

            //Register some messages to be stored in a database
            spacecraft.get_message("Out_EclipseMsg").subscribe(dataSampleRate)
            navigator.get_message("Out_NavAttMsg").subscribe(dataSampleRate)
            sunPointFsw.get_message("Out_AttGuidMsg").subscribe(dataSampleRate)
            solarPanel.get_message("Out_PowerSourceMsg").subscribe(dataSampleRate)
            reactionWheels.get_message("Out_RWSpeedMsg").subscribe(dataSampleRate)

            print("Simulation Configured")

            //Execute the simulation to be ticked
            print("Tick the simulation for:",tickIterations,"steps with a step size of", tickSize,"(",tickSize*Double(tickIterations),"seconds )" )

            for i in 0..<10
            {
                sim.tick(tickSize,tickIterations/10)
                print("Percentage Progress:", i*10)
            }
            print("Percentage Progress: 100")

            //Get the data from the simulation
            print("Exporting data")

            let dataPower = solarPanel.get_message("Out_PowerSourceMsg").fetch("Power")

            do
            {
                if let outputPath = ProcessInfo.processInfo.environment["NOMINAL_API_OUTPUT_PATH"]
                {
                    try String(jsonModule.dumps(dataPower))!.write(toFile: "\(outputPath)/Data_solar_panel_Power.txt", atomically: true, encoding: .utf8)
                    print("Power Data exported")
                }
                else
                {
                    print("OUTPUT_PATH Environment variable not set.")
                }
            }
            catch
            {
                print("Error writing data to file")
            }

            //Export the data in a format supported by Gilmour Space's GOATS Software
            for entry in dataPower {
                let time = entry["time"] ?? builtinsModule.None
                let powerData = entry["data"] ?? builtinsModule.None
                if time != builtinsModule.None, powerData != builtinsModule.None {
                    let power = powerData["Power"] ?? builtinsModule.None
                    if power != builtinsModule.None {
                        print("[[GIMP_Client Result]] Power|\(power)|\(time)")
                    }
                }
            }

            print("Simulation Complete")
        }
        else
        {
            print("NOMINAL_API_KEY Environment Variable not set.")
        }
    }
    }