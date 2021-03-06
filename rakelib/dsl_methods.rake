require 'yajl'

METADATA_FILE = 'chef_dsl_metadata.json'

file METADATA_FILE do
  require_chef
  chef_dsl_metadata = {:dsl_methods => chef_dsl_methods,
                       :node_methods => chef_node_methods,
                       :actions => chef_resource_actions,
                       :attributes => chef_resource_attributes}
  json = Yajl::Encoder.encode(chef_dsl_metadata, :pretty => true)
  File.open(METADATA_FILE, 'w'){|f| f.write(json)}
end

def require_chef
  require 'chef'
  require 'chef/mixin/convert_to_class_name'
  include Chef::Mixin::ConvertToClassName
end

def chef_dsl_methods
  (Chef::Node.public_instance_methods +
   Chef::Mixin::RecipeDefinitionDSLCore.included_modules.map do |mixin|
     mixin.public_instance_methods
   end).flatten.sort.uniq
end

def chef_node_methods
  Chef::Node.public_instance_methods.flatten.sort.uniq
end

def chef_resource_actions
  chef_resources do |resource_klazz,resource|
    instance = resource.new('dsl')
    if instance.respond_to?(:allowed_actions)
      [convert_to_snake_case(resource_klazz.to_s),
        instance.allowed_actions.sort]
    end
  end
end

def chef_resource_attributes
  chef_resources do |resource_klazz,resource|
    [convert_to_snake_case(resource_klazz.to_s),
       resource.public_instance_methods(true).sort]
  end
end

private

def chef_resources
  resources = Chef::Resource.constants.sort.map do |resource_klazz|
    resource = Chef::Resource.const_get(resource_klazz)
    if resource.respond_to?(:public_instance_methods) and
       resource.ancestors.include?(Chef::Resource)
      yield resource_klazz, resource
    end
  end
  Hash[resources]
end
