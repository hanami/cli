# frozen_string_literal: true

RSpec.describe "bin/run", :app do
  let(:output) do
    Open3.capture3("bin/run #{args.join(" ")}", chdir: app.root)[1]
  end

  context "no args" do
    let(:args) { [] }

    it "prints out usage" do
      expect(output).to include("console")
      expect(output).to include("db [SUBCOMMAND]")
    end
  end

  context "db" do
    let(:args) { ["db"] }

    it "prints put db usage" do
      expect(output).to include("db create")
      expect(output).to include("db structure [SUBCOMMAND]")
    end
  end
end
