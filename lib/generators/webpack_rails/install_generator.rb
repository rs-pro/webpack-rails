module WebpackRails
  # :nodoc:
  class InstallGenerator < ::Rails::Generators::Base
    source_root File.expand_path("../../../../example", __FILE__)

    desc "Install everything you need for Webpack 5 + Rails 7/8 + Propshaft integration"

    def add_foreman_to_gemfile
      gem 'foreman'
    end

    def copy_procfile
      copy_file "Procfile", "Procfile"
    end

    def copy_package_json
      copy_file "package.json", "package.json"
    end

    def copy_webpack_conf
      copy_file "webpack.config.js", "config/webpack.config.js"
    end

    def create_webpack_application_js
      empty_directory "webpack"
      create_file "webpack/application.js" do
        <<-EOF.strip_heredoc
        // Webpack 5 + Rails application entry point
        console.log("Hello from Webpack 5 + Rails!");

        // Example: Import additional modules
        // import './components/navbar';
        // import './stylesheets/application.scss';
        EOF
      end
    end

    def add_to_gitignore
      append_to_file ".gitignore" do
        <<-EOF.strip_heredoc
        # Added by webpack-rails
        /node_modules
        /public/webpack
        *.log
        EOF
      end
    end

    def run_npm_install
      if yes?("Would you like us to run 'npm install' for you?")
        run "npm install"
      else
        say "Remember to run 'npm install' to install webpack dependencies!", :yellow
      end
    end

    def run_bundle_install
      if yes?("Would you like us to run 'bundle install' for you?")
        run "bundle install"
      end
    end

    def whats_next
      say "\n" + "="*80, :green
      say "Webpack 5 + Rails 7/8 + Propshaft Setup Complete!", :green
      say "="*80 + "\n", :green

      say "Next steps:", :cyan
      say "  1. Add webpack assets to your layout:", :yellow
      say "     <%= javascript_include_tag *webpack_asset_paths('application') %>", :white
      say ""
      say "  2. Run development servers:", :yellow
      say "     foreman start", :white
      say "     (or run 'rails s' and 'npm run dev' in separate terminals)", :white
      say ""
      say "  3. For production deployment:", :yellow
      say "     rake webpack:compile", :white
      say "     (compiles assets to public/webpack/ with .digested extension)", :white
      say ""
      say "  4. Webpack outputs to public/webpack/ which propshaft automatically serves", :yellow
      say ""
      say "Documentation: https://gitlab.com/rocket-science/webpack-rails", :cyan
      say "\n" + "="*80 + "\n", :green
    end
  end
end
