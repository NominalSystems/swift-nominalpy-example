// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import PythonKit

public struct SwiftNominalpyExample {

    public static func run()
    {

        let url = "https://api.nominalsys.com"
        let port = Python.None

        if let apiKey = ProcessInfo.processInfo.environment["NOMINAL_API_KEY"]
        {
            print("Nominal API Key Recieved")

            let credentials = Python.import("nominalpy.connection.credentials")
            let auth: PythonObject = credentials.Credentials(url,port,apiKey)

            let simulation = Python.import("nominalpy.objects.simulation")
            let sim: PythonObject = simulation.Simulation(auth)

            print("Pre Tick sim.get_time: ",sim.get_time())

            let nominalpy = Python.import("nominalpy")
            let types = nominalpy.types

            let datetime = Python.import("datetime")

            //Configure the Universe with an epoch
            let universe = sim.get_system(types.UNIVERSE, Epoch: datetime.datetime(2022, 1, 1))

            let astro = Python.import("nominalpy.maths.astro")

            //Compute the orbit from the Keplerian elements to a state vector of (position, velocity)
            let orbit: PythonObject = astro.classical_to_vector_elements(6671, inclination: 35, true_anomaly: 16)

            let np = Python.import("numpy")

            //Adds the spacecraft
            let spacecraft: PythonObject = sim.add_component(types.SPACECRAFT,
            TotalMass: 750.0,
                TotalCenterOfMass: np.array([0, 0, 0]),
            TotalMomentOfInertia: np.array([[900, 0, 0], [0, 800, 0], [0, 0, 600]]),
                Position: orbit[0],
                Velocity: orbit[1],
                AttitudeRate: np.array([0.2, 0.1, 0.05]))

            //Adds reaction wheels
            let reactionWheels: PythonObject = sim.add_component("ReactionWheelArray",spacecraft)

            let rw1: PythonObject = sim.add_component("ReactionWheel",reactionWheels,WheelSpinAxis_B:np.array([1,0,0]))
            let rw2: PythonObject = sim.add_component("ReactionWheel",reactionWheels,WheelSpinAxis_B:np.array([0,1,0]))
            let rw3: PythonObject = sim.add_component("ReactionWheel",reactionWheels,WheelSpinAxis_B:np.array([0,0,1]))

            //Adds a simple Navigator
            let navigator: PythonObject = sim.add_component("SimpleNavigator",spacecraft)

            //Adds a Solar Panel
            let solarPanel: PythonObject = sim.add_component("SolarPanel",spacecraft,Area:0.01,Efficiency:0.23)

            //Adds in Sun Safe Pointing
            let sunPointFSW: PythonObject = sim.add_component("SunSafePointingSoftware",spacecraft,
                minUnitMag:0.001,
                SmallAngle:0.001,
                SunBodyVector:solarPanel.get_value("LocalUp"),
                Omega_RN_B:np.array([0,0,0]),
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
                In_AttGuidMsg:sunPointFSW.get_value("Out_AttGuidMsg"),
                In_VehicleConfigMsg:spacecraft.get_value("Out_VehicleConfigMsg"))

            //Add in the motor torque software
            let motorTorqueFsw: PythonObject = sim.add_component("ReactionWheelMotorTorqueSoftware",spacecraft,
                In_CmdTorqueBodyMsg:mrpFeedbackFsw.get_value("Out_CmdTorqueBodyMsg"),
                In_RWArrayConfigMsg:reactionWheels.get_value("Out_RWArrayConfigMsg"))

            //Connect up to the reaction wheels
            reactionWheels.set_value("In_ArrayMotorTorqueMsg", motorTorqueFsw.get_value("Out_ArrayMotorTorqueMsg"))

            //Register some messages to be stored in a database
            spacecraft.get_message("Out_EclipseMsg").subscribe(5.0)
            navigator.get_message("Out_NavAttMsg").subscribe(5.0)
            sunPointFSW.get_message("Out_AttGuidMsg").subscribe(5.0)
            solarPanel.get_message("Out_PowerSourceMsg").subscribe(5.0)
            reactionWheels.get_message("Out_RWSpeedMsg").subscribe(5.0)

            //Execute the simulation to be ticked
            sim.tick(0.05,2000)

            print("Post Tick sim.get_time: ",sim.get_time())
            print(solarPanel.get_message("Out_PowerSourceMsg").fetch("Power"))

			do 
			{
            	if let outputPath = ProcessInfo.processInfo.environment["NOMINAL_API_OUTPUT_PATH"]
            	{
                	let json = Python.import("json")
                	let data = String(json.dumps(solarPanel.get_message("Out_PowerSourceMsg").fetch("Power")))!
                	try data.write(toFile: "\(outputPath)/Data_Solarpanel_Power.txt", atomically: true, encoding: .utf8)
            	}
			} 
			catch 
			{
				print("Error writing data to file")
			}
        }
        else
        {
            print("Environment variable not set.")
        }
    }
}