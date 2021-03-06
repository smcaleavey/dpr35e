classdef pulserProperties < handle

    properties
        Address
        ModelName
        SerialNumber
        FirmwareRevision
        HardwareRevision
        BoardNumber
    end


    methods %(Access = ?dpr35e) 
       
        function setPropertiesByCommandNumber(obj,command,value)
            switch command
                case 0
                    obj.ModelName=value;
                case 1
                    obj.SerialNumber=value;
                case 2
                    obj.FirmwareRevision=value(1);
                    obj.HardwareRevision=value(2);
                case 3
                    obj.BoardNumber=value;
            end

        end

    end

end
