# Copyright (c) 2009-2013 The University of Manchester, UK.
#
# See LICENCE file for details.
#
# Authors: Finn Bacall
#          Robert Haines
#          David Withers
#          Mannie Tagarira
#
# This is the module containing the T2Flow model implementation i.e. the
# model structure/definition and all its internals.

require 't2flow/model/coordination'
require 't2flow/model/dataflow'
require 't2flow/model/datalink'
require 't2flow/model/port'
require 't2flow/model/processor'
require 't2flow/model/semantic_annotation'

module T2Flow # :nodoc:

  # The model for a given Taverna 2 workflow.
  class Model
    # The list of all the dataflows that make up the workflow.
    attr_accessor :dataflows

    # The list of any dependencies that have been found inside the workflow.
    attr_accessor :dependencies

    # Creates an empty model for a Taverna 2 workflow.
    def initialize
      @dataflows = []
      @dependencies = []
    end

    # Retrieve the top level dataflow's name
    def name
      main.name
    end

    # Retrieve the top level dataflow ie the MAIN (containing) dataflow
    def main
      @dataflows[0]
    end

    # Retrieve the dataflow with the given ID
    def dataflow(df_id)
      df = @dataflows.select { |x| x.dataflow_id == df_id }
      return df[0]
    end

    # Retrieve ALL the processors containing beanshells within the workflow.
    def beanshells
      self.all_processors.select { |x| x.type == "beanshell" }
    end

    # Retrieve ALL processors of that are webservices WITHIN the model.
    def web_services
      self.all_processors.select { |x| x.type =~ /wsdl|soaplab|biomoby/i }
    end

    # Retrieve ALL local workers WITHIN the workflow
    def local_workers
      self.all_processors.select { |x| x.type =~ /local/i }
    end

    # Retrieve the datalinks from the top level of a nested workflow.
    # If the workflow is not nested, retrieve all datalinks.
    def datalinks
      self.main.datalinks
    end

    # Retrieve ALL the datalinks within a nested workflow
    def all_datalinks
      links = []
      @dataflows.each { |dataflow| links << dataflow.datalinks }
      return links.flatten
    end

    # Retrieve the annotations specific to the workflow.  This does not return 
    # any annotations from workflows encapsulated within the main workflow.
    def annotations
      self.main.annotations
    end

    # Retrieve processors from the top level of a nested workflow.
    # If the workflow is not nested, retrieve all processors.
    def processors
      self.main.processors
    end

    # Retrieve ALL the processors found in a nested workflow
    def all_processors
      procs =[]
      @dataflows.each { |dataflow| procs << dataflow.processors }
      return procs.flatten
    end

    # Retrieve coordinations from the top level of a nested workflow.
    # If the workflow is not nested, retrieve all coordinations.
    def coordinations
      self.main.coordinations
    end

    # Retrieve ALL the coordinations found in a nested workflow
    def all_coordinations
      coordinations =[]
      @dataflows.each { |dataflow| coordinations << dataflow.coordinations }
      return coordinations.flatten
    end

    # Retrieve the sources(inputs) to the workflow
    def sources
      self.main.sources
    end

    # Retrieve ALL the sources(inputs) within the workflow
    def all_sources
      sources =[]
      @dataflows.each { |dataflow| sources << dataflow.sources }
      return sources.flatten
    end

    # Retrieve the sinks(outputs) to the workflow
    def sinks
      self.main.sinks
    end

    # Retrieve ALL the sinks(outputs) within the workflow
    def all_sinks
      sinks =[]
      @dataflows.each { |dataflow| sinks << dataflow.sinks }
      return sinks.flatten
    end

    # Retrieve the unique dataflow ID for the top level dataflow.
    def model_id
      self.main.dataflow_id
    end

    # For the given dataflow, return the beanshells and/or services which 
    # have direct links to or from the given processor.
    # If no dataflow is specified, the top-level dataflow is used.
    # This does a recursive search in nested workflows.
    # == Usage
    #   my_processor = model.processor[0]
    #   linked_processors = model.get_processors_linked_to(my_processor)
    #   processors_feeding_into_my_processor = linked_processors.sources
    #   processors_feeding_from_my_processor = linked_processors.sinks
    def get_processor_links(processor)
      return nil unless processor
      proc_links = ProcessorLinks.new

      # SOURCES
      sources = self.all_datalinks.select { |x| x.sink =~ /#{processor.name}:.+/ }
      proc_links.sources = []

      # SINKS
      sinks = self.all_datalinks.select { |x| x.source =~ /#{processor.name}:.+/ }
      proc_links.sinks = []
      temp_sinks = []
      sinks.each { |x| temp_sinks << x.sink }

      # Match links by port into format
      # my_port:name_of_link_im_linked_to:its_port
      sources.each do |connection|
        link = connection.sink
        connected_proc_name = link.split(":")[0]
        my_connection_port = link.split(":")[1]

        if my_connection_port
          source = my_connection_port << ":" << connection.source
          proc_links.sources << source if source.split(":").size == 3
        end
      end

      sinks.each do |connection|
        link = connection.source
        connected_proc_name = link.split(":")[0]
        my_connection_port = link.split(":")[1]

        if my_connection_port
          sink = my_connection_port << ":" << connection.sink
          proc_links.sinks << sink if sink.split(":").size == 3
        end
      end

      return proc_links
    end
  end
end
