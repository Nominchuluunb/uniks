#!/usr/bin/env ruby
# Adds required Swift Package Manager dependencies to the Uniks Xcode project.

require 'xcodeproj'

PROJECT_PATH = 'uniks.xcodeproj'

DEPENDENCIES = [
  {
    name: 'mlx-swift-examples',
    url: 'https://github.com/ml-explore/mlx-swift-examples.git',
    branch: 'main',
    products: {
      'uniks' => ['MLXLMCommon'],
      'uniksTests' => ['MLXLMCommon']
    }
  },
  {
    name: 'SwiftFTS',
    url: 'https://github.com/cbess/SwiftFTS.git',
    branch: 'main',
    products: {
      'uniks' => ['SwiftFTS'],
      'uniksTests' => ['SwiftFTS']
    }
  }
]

project = Xcodeproj::Project.open(PROJECT_PATH)

DEPENDENCIES.each do |dep|
  # 1. Create or find remote package reference
  package_ref = project.root_object.package_references.find { |ref| ref.repositoryURL == dep[:url] }
  unless package_ref
    package_ref = project.new(Xcodeproj::Project::Object::XCRemoteSwiftPackageReference)
    package_ref.repositoryURL = dep[:url]
    package_ref.requirement = {
      'kind' => 'branch',
      'branch' => dep[:branch]
    }
    project.root_object.package_references << package_ref
    puts "Added package reference: #{dep[:name]}"
  end

  # 2. Add product dependencies to each target
  dep[:products].each do |target_name, product_names|
    target = project.targets.find { |t| t.name == target_name }
    unless target
      warn "Target #{target_name} not found, skipping"
      next
    end

    product_names.each do |product_name|
      existing = target.package_product_dependencies.find { |pd| pd.product_name == product_name }
      if existing
        puts "  Product #{product_name} already exists on #{target_name}"
        next
      end

      product_dep = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
      product_dep.package = package_ref
      product_dep.product_name = product_name
      target.package_product_dependencies << product_dep

      # 3. Link in Frameworks build phase
      frameworks_phase = target.frameworks_build_phase
      build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
      build_file.product_ref = product_dep
      frameworks_phase.files << build_file

      puts "  Added product #{product_name} to #{target_name}"
    end
  end
end

project.save
puts "Project saved."
