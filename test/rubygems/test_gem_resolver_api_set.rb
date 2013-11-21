require 'rubygems/test_case'

class TestGemResolverAPISet < Gem::TestCase

  def setup
    super

    @DR = Gem::Resolver
    @dep_uri = URI "#{@gem_repo}api/v1/dependencies"
  end

  def test_initialize
    set = @DR::APISet.new

    assert_equal URI('https://rubygems.org/api/v1/dependencies'), set.dep_uri
    assert_equal URI('https://rubygems.org'),                     set.uri
    assert_equal Gem::Source.new(URI('https://rubygems.org')),    set.source
  end

  def test_initialize_uri
    set = @DR::APISet.new @dep_uri

    assert_equal URI("#{@gem_repo}api/v1/dependencies"), set.dep_uri
    assert_equal URI("#{@gem_repo}"),                     set.uri
  end

  def test_prefetch
    spec_fetcher do |fetcher|
      fetcher.spec 'a', 1
    end

    data = [
      { :name         => 'a',
        :number       => '1',
        :platform     => 'ruby',
        :dependencies => [], },
    ]

    @fetcher.data["#{@dep_uri}?gems=a,b"] = Marshal.dump data
    @fetcher.data["#{@dep_uri}?gems=b"]   = Marshal.dump []

    set = @DR::APISet.new @dep_uri

    a_dep = @DR::DependencyRequest.new dep('a'), nil
    b_dep = @DR::DependencyRequest.new dep('b'), nil

    set.prefetch [a_dep, b_dep]

    assert_equal %w[a-1], set.find_all(a_dep).map { |s| s.full_name }
    assert_empty          set.find_all(b_dep)
  end

  def test_prefetch_cache
    spec_fetcher do |fetcher|
      fetcher.spec 'a', 1
    end

    data = [
      { :name         => 'a',
        :number       => '1',
        :platform     => 'ruby',
        :dependencies => [], },
    ]

    @fetcher.data["#{@dep_uri}?gems=a"] = Marshal.dump data

    set = @DR::APISet.new @dep_uri

    a_dep = @DR::DependencyRequest.new dep('a'), nil
    b_dep = @DR::DependencyRequest.new dep('b'), nil

    set.prefetch [a_dep]

    @fetcher.data.delete "#{@dep_uri}?gems=a"
    @fetcher.data["#{@dep_uri}?gems=b"]   = Marshal.dump []

    set.prefetch [a_dep, b_dep]
  end

  def test_prefetch_cache_missing
    spec_fetcher do |fetcher|
      fetcher.spec 'a', 1
    end

    data = [
      { :name         => 'a',
        :number       => '1',
        :platform     => 'ruby',
        :dependencies => [], },
    ]

    @fetcher.data["#{@dep_uri}?gems=a,b"] = Marshal.dump data

    set = @DR::APISet.new @dep_uri

    a_dep = @DR::DependencyRequest.new dep('a'), nil
    b_dep = @DR::DependencyRequest.new dep('b'), nil

    set.prefetch [a_dep, b_dep]

    @fetcher.data.delete "#{@dep_uri}?gems=a,b"

    set.prefetch [a_dep, b_dep]
  end

end

