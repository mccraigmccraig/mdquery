$: << File.expand_path('..', __FILE__) if !$:.include?(File.expand_path('..', __FILE__))
require 'mdquery/dsl'

# a DSL for specifying analytic queries
module MDQuery

  # define a Dataset with the DSL
  # * +proc+ the DatasetDSL Proc
  def self.dataset(&proc)
    MDQuery::DSL::DatasetDSL.new(&proc).send(:build)
  end

end
