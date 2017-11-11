module Fastlane
  module Actions
    module SharedValues
      TERRAFORM_CUSTOM_VALUE = :TERRAFORM_CUSTOM_VALUE
    end

    class TerraformAction < Action
      def self.run(params)
        var_file = params[:var_file]
        state_file = params[:state_file]
        vars = params[:vars]

        cmd = "cd #{params[:infrastructure_folder].shellescape} && terraform apply"

        unless var_file.nil? 
          cmd << " -var-file #{var_file}"
        end
        unless state_file.nil? 
          cmd << " -state #{state_file}"
        end

        vars.each do |k, v|
          cmd << " -var '#{k}=#{v}'"
        end

        result = Actions.sh cmd
        outputs_idx = result.lines.index { |l| l.strip == "Outputs:"}
        output_vars_lines = result.lines.last(result.lines.count - (outputs_idx + 1) - 1)
        output_vars = {}
        output_vars["no_changes?"] = result.lines.any? { |l| l =~ /0 added, 0 changed, 0 destroyed/ }

        output_vars_lines.each do |l|
          var = l.split("=")

          # Take out any escape codes
          key = var.first.gsub(/(\\\w)|(\[\d\w)/, "").strip
          value = var.last.gsub(/(\\\w)|(\[\d\w)/, "").strip
          output_vars.merge!(key => value)
        end

        output_vars
      end

      def self.description
        "Run terraform apply to bring the infrastructure up to date"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :var_file,
                                       description: "Terraform var file",
                                       optional: true
                                      ),
          FastlaneCore::ConfigItem.new(key: :state_file,
                                       description: "Terraform state file",
                                       optional: true
                                      ),
          FastlaneCore::ConfigItem.new(key: :infrastructure_folder,
                                       description: "The subfolder where the whole infrastructure is defined",
                                       default_value: "."
                                      ),
          FastlaneCore::ConfigItem.new(key: :vars,
                                       description: "Additional variables to pass to terraform in form of a hash",
                                       is_string: false,
                                       default_value: {}
                                      )
        ]
      end

      def self.authors
        ["milch"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
