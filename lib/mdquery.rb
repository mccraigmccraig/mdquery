require 'mdquery/dsl'

# a DSL for specifying analytic queries
module MDQuery

    def self.dataset(&proc)
      MDQuery::DSL::DatasetDSL.new(&proc)
    end

end
