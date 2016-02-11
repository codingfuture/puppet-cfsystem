require 'spec_helper'
describe 'cfsystem' do

  context 'with defaults for all parameters' do
    it { should contain_class('cfsystem') }
  end
end
