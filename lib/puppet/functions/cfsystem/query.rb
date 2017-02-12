#
# Copyright 2017 (c) Andrey Galkin
#

Puppet::Functions.create_function(:'cfsystem::query') do
    dispatch :cf_cached_query do
        param 'Variant[Array,String[1]]', :query
    end
    
    def cf_cached_query(query)
        cache = PuppetX::CfSystem::Util.mutablePersistence(self, 'query_cache')
        cache_key = query.to_s
        res = cache[cache_key]
        
        if res.nil?
            res = call_function(:puppetdb_query, query)
            cache[cache_key] = res
        end
        
        return res
    end
end
