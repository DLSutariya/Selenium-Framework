require 'socket'
require 'serialport'
require 'timeout'

module MA1000AutomationTool
  class CmdHolderObj

    #Read only class variables
    attr_reader :ilv_req_pkt, :ilv_rep_pkt, :bio_req_pkt, :bio_ack_pkt, :bio_res_pkt

    #Protocol Type Enum
    module ProtoType
      UNKNOWN = 0
      ILV = 1
      SERIALCMD = 2
    end

    #CmdHolderList constructor
    #Available options:
    #     :ilv_req_pkt => Request packet of ILVCommand
    #     :ilv_rep_pkt => Receive Packet of ILVCommand
    #     :bio_req_pkt => Request Packet of Serial command
    #     :bio_ack_pkt => Receive acknowledge of Serial command
    #     :bio_res_pkt => Receive Responce of Serial command

    def initialize(options)

      $test_logger.log("Initialize CmdHolderList with #{options}")

      #check that ilv protocol option and bio command option can't be specified at a time

      if (((options[:ilv_req_pkt]) && (options[:bio_req_pkt])) or
      ((options[:ilv_req_pkt]) && (options[:bio_ack_pkt])) or
      ((options[:ilv_req_pkt]) && (options[:bio_res_pkt])))
        raise "specified command holder option is not a valid option"
      elsif (((options[:ilv_req_pkt]) && (options[:bio_req_pkt]) && (options[:bio_res_pkt])) or
      ((options[:ilv_req_pkt]) && (options[:bio_req_pkt]) && (options[:bio_ack_pkt])) or
      ((options[:ilv_req_pkt]) && (options[:bio_ack_pkt]) && (options[:bio_res_pkt])) or
      ((options[:bio_req_pkt]) && (options[:ilv_req_pkt]) && (options[:bio_ack_pkt]) && (options[:bio_res_pkt])))
        raise "specified command holder option is not a valid option"
      elsif (((options[:ilv_rep_pkt]) && (options[:bio_req_pkt])) or
      ((options[:ilv_rep_pkt]) && (options[:bio_ack_pkt])) or
      ((options[:ilv_rep_pkt]) && (options[:bio_res_pkt])))
        raise "specified command holder option is not a valid option"
      elsif (((options[:ilv_rep_pkt]) && (options[:bio_req_pkt]) && (options[:bio_res_pkt])) or
      ((options[:ilv_rep_pkt]) && (options[:bio_req_pkt]) && (options[:bio_ack_pkt])) or
      ((options[:ilv_rep_pkt]) && (options[:bio_ack_pkt]) && (options[:bio_res_pkt])) or
      ((options[:bio_req_pkt]) && (options[:bio_ack_pkt]) && (options[:ilv_rep_pkt]) && (options[:bio_res_pkt])) or
      ((options[:bio_res_pkt]) && (options[:ilv_req_pkt]) && (options[:bio_req_pkt]) && (options[:bio_ack_pkt]) && (options[:ilv_rep_pkt])))
        raise "specified command holder option is not a valid option"
      end

      @proto_type = ProtoType::UNKNOWN
      if !options[:ilv_req_pkt] and !options[:bio_req_pkt]
        raise "Specify at least one command"
      elsif options[:bio_res_pkt] and !options[:bio_ack_pkt]
        raise "Please provide Bio request packet"
      elsif options[:ilv_req_pkt]
        @proto_type = ProtoType::ILV
      elsif options[:ilv_req_pkt] and options[:ilv_rep_pkt]
        @proto_type = ProtoType::ILV
      elsif options[:bio_req_pkt] and options[:bio_ack_pkt] and options[:bio_res_pkt]
        @proto_type = ProtoType::SERIALCMD
      elsif options[:bio_req_pkt] and options[:bio_res_pkt]
        @proto_type = ProtoType::SERIALCMD
      elsif options[:bio_req_pkt] and options[:bio_ack_pkt]
        @proto_type = ProtoType::SERIALCMD
      end

      #options avalible
      @ilv_req_pkt = nil
      @ilv_rep_pkt = nil
      @bio_req_pkt = nil
      @bio_ack_pkt = nil
      @bio_res_pkt = nil

      case @proto_type
      when ProtoType::ILV
        @ilv_req_pkt = options[:ilv_req_pkt] if options[:ilv_req_pkt] != nil
        @ilv_rep_pkt = options[:ilv_rep_pkt] if options[:ilv_rep_pkt] != nil
      when ProtoType::SERIALCMD
        @bio_req_pkt = options[:bio_req_pkt] if options[:bio_req_pkt] != nil
        @bio_ack_pkt = options[:bio_ack_pkt] if options[:bio_ack_pkt] != nil
        @bio_res_pkt = options[:bio_res_pkt] if options[:bio_res_pkt] != nil
      else
      raise "No Protocol type specified!"
      end

    end

  end
end
