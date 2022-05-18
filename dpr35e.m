classdef dpr35e < handle & matlab.mixin.SetGet

    properties (Constant, Hidden)
        PulserCommand = {'o',["Disabled" "Enabled"],[0 1]}
        BlinkCommand = {'b',["Blink" "On"],[248 255]}
        DampingCommand = {'d',[1000 333 200 143 111 91 77 67 58 52 47 43 40 37 34 32],0:15}
        EnergyCommand = {'e',0:3,0:3}
        GainCommand = {'g',-19:60,0:79}
        HighPassCommand = {'h',[0 1 2.5 5 7.5 12.5],0:5}
        ImpedanceCommand = {'z',["High" "Low"],[0 1]}
        LowPassCommand = {'l',[3 7.5 10 15 22.5 35],0:5}
        PRFCommand = {'p',[100 200:200:1000 1250:250:2000 2500:500:5000],0:15}
        ReceiverModeCommand = {'r',["PulseEcho" "Through"],[0 1]}
        TriggerCommand = {'t',["Internal" "External"],[0 1]}
        VoltageCommand = {'v',100+25*(0:15),0:15}
        baudRate = 4800
    end

    properties (Access=private)
        serialPort
        DeviceInformation pulserProperties
    end

    properties (SetAccess=private)
        serialPortName
        isConnected logical = false
        AvailableAddresses = [ ]
        SelectedAddress = [ ];
        ModelName =[]
        SerialNumber = []
    end

    properties (Dependent, SetAccess=private)
        PulserStatus
    end

    properties (Dependent)
        PowerLight {mustBeMember(PowerLight,["Blink" "On"])}
        Damping {mustBeMember(Damping,[1000 333 200 143 111 91 77 67 58 52 47 43 40 37 34 32])}
        Energy {mustBeMember(Energy,0:3)}
        FilterHighPassCutoffMHz {mustBeMember(FilterHighPassCutoffMHz,[0 1 2.5 5 7.5 12.5])} 
        FilterLowPassCutoffMHz {mustBeMember(FilterLowPassCutoffMHz,[3 7.5 10 15 22.5 35])}
        Gain_dB {mustBeInteger,mustBeInRange(Gain_dB,-19,60)}
        Impedance {mustBeMember(Impedance,["Low" "High"])}
        PulseRepetitionFrequency {mustBeMember(PulseRepetitionFrequency,[100 200:200:1000 1250:250:2000 2500:500:5000])}
        ReceiverMode {mustBeMember(ReceiverMode,["PulseEcho" "Through"])} 
        Trigger {mustBeMember(Trigger,["Internal" "External"])} 
        Voltage
    end

    methods

        function obj = dpr35e(options)
            arguments
                options.port
            end

            if isfield(options,"port")
                if ~ismember(options.port,serialportlist("available"))
                    warning("%s is not an available serial port. Available ports are %s",options.port,join(serialportlist("available")));
                end
                obj.serialPortName=options.port;
            end

        end

        function connect(obj,options)
            arguments
                obj dpr35e
                options.assign logical = false
            end
            if obj.isConnected
                warning("Already connected")
                return
            end
            obj.serialPort=serialport(obj.serialPortName,obj.baudRate,"Timeout",1);
            addressCount=0;
            obj.disableAddressing;
            data=obj.inquire;
            while ~isempty(data.Address)
                addressCount=addressCount+1;
                if options.assign 
                    data.Address=addressCount;
                    obj.assignAddress(data.Address);
                    obj.serialPort.flush;
                    disp(obj.inquire)
                end
                obj.AvailableAddresses(addressCount)=data.Address;
                obj.DeviceInformation(addressCount)=data;
                obj.enableAddressing(data.Address);
                data=obj.inquire;
            end
            if addressCount>0
                obj.isConnected = true;
                obj.selectAddress(obj.AvailableAddresses(1));
                fprintf('Found %d pulser(s). Selected %s at address %d\n',addressCount,obj.DeviceInformation(1).ModelName,obj.SelectedAddress);
            else
                warning("Did not find any pulsers on %s",obj.serialPortName);
                obj.disconnect;
            end
        end

        function disconnect(obj)
            delete(obj.serialPort);
            obj.serialPort=[];
            obj.isConnected = false;
        end

        function enablePulser(obj)
            send(obj,obj.PulserCommand,"Enabled");
        end

        function disablePulser(obj)
            send(obj,obj.PulserCommand,"Disabled");
        end

        function selectAddress(obj,value)
            if ismember(value,obj.AvailableAddresses)
                obj.SelectedAddress=value;
                addressIndex=find(obj.AvailableAddresses==value);
                obj.ModelName=obj.DeviceInformation(addressIndex).ModelName;
                obj.SerialNumber=obj.DeviceInformation(addressIndex).SerialNumber;
            else
                error('Address must be selected from available addresses')
            end
        end

        function listDevices(obj)
            for n=1:length(obj.DeviceInformation)
                disp(obj.DeviceInformation(n))
            end
        end

        function value=get.PulserStatus(obj)
            value=query(obj,obj.PulserCommand);
        end

        function value = get.PowerLight(obj)
            value=query(obj,obj.BlinkCommand);
        end

        function set.PowerLight(obj,value)
            send(obj,obj.BlinkCommand,value);
        end

        function value = get.Damping(obj)
            value=query(obj,obj.DampingCommand);
        end

        function set.Damping(obj,value)
            send(obj,obj.DampingCommand,value);
        end

        function value = get.Energy(obj)
            value=query(obj,obj.EnergyCommand);
        end

        function set.Energy(obj,value)
            send(obj,obj.EnergyCommand,value);
        end

        function value = get.Gain_dB(obj)
            value=query(obj,obj.GainCommand);
        end

        function set.Gain_dB(obj,value)
            send(obj,obj.GainCommand,value);
        end

        function value = get.FilterHighPassCutoffMHz(obj)
            value=query(obj,obj.HighPassCommand);
        end

        function set.FilterHighPassCutoffMHz(obj,value)
            send(obj,obj.HighPassCommand,value);
        end

        function value = get.FilterLowPassCutoffMHz(obj)
            value=query(obj,obj.LowPassCommand);
        end

        function set.FilterLowPassCutoffMHz(obj,value)
            send(obj,obj.LowPassCommand,value);
        end

        function value = get.Impedance(obj)
            value=query(obj,obj.ImpedanceCommand);
        end

        function set.Impedance(obj,value)
            send(obj,obj.ImpedanceCommand,value);
        end

        function value = get.PulseRepetitionFrequency(obj)
            value=query(obj,obj.PRFCommand);
        end

        function set.PulseRepetitionFrequency(obj,value)
            send(obj,obj.PRFCommand,value);
        end

        function value = get.ReceiverMode(obj)
            value=query(obj,obj.ReceiverModeCommand);
        end

        function set.ReceiverMode(obj,value)
            send(obj,obj.ReceiverModeCommand,value);
        end

        function value = get.Trigger(obj)
            value=query(obj,obj.TriggerCommand);
        end

        function set.Trigger(obj,value)
            send(obj,obj.TriggerCommand,value);
        end
        
        function value = get.Voltage(obj)
            value=query(obj,obj.VoltageCommand);
        end

        function set.Voltage(obj,value)
            send(obj,obj.VoltageCommand,value);
        end
    end

    methods (Access=private)

        function value = query(obj,option)
            obj.serialPort.flush;
            command = bitor(uint8(128),uint8(option{1}));
            obj.serialPort.write([obj.SelectedAddress 0 command 0 0],'uint8');
            reply = obj.serialPort.read(5,'uint8');
            value = option{2}(double(reply(4))==option{3});
        end

        function send(obj,option,value)
            val = option{3}(value==option{2});
            assert(isscalar(val));
            obj.serialPort.write([obj.SelectedAddress 0 option{1} val 0],'uint8');
            obj.serialPort.read(5,'uint8');
        end
    
        function disableAddressing(obj)
            % Corresponds to the "D Command" in DPR35e manual, page VI-3
            obj.serialPort.write([0 0 'D' 0 0],'uint8');
        end

        function enableAddressing(obj,address)
            % Corresponds to the "E Command" in DPR35e manual, page VI-5
            obj.serialPort.write([0 0 'E' address 0],'uint8');
        end

        function [data]=inquire(obj)
            % Corresponds to the "I Command in DPR35e manual, page VI-3
            data=pulserProperties;
            command_byte=uint8(0:3); % commands for model, serial no, rev., board no.
            for nn=1:length(command_byte)
                obj.serialPort.write([0 0 'I' command_byte(nn) 0],'uint8');
                warning('off','serialport:serialport:ReadWarning')                
                reply=obj.serialPort.read(3,"uint8");
                warning('on','serialport:serialport:ReadWarning')                
                if isempty(reply) 
                    return
                elseif reply(3)~='I'
                    warning('Read error getting device information -- check values')
                    return
                end
                data.Address=reply(1);
                data.setPropertiesByCommandNumber(command_byte(nn),obj.serialPort.read(reply(2)-1,"char"));
                pause(0.05);
            end
        end

        function assignAddress(obj,address)
            % Corresponds to the "A Command" in DPR35e manual, page VI-5
            obj.serialPort.write([0 0 'A' address 0],'uint8');
        end

    end

end