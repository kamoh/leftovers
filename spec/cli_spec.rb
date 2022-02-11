# frozen_string_literal: true

require 'parallel'

RSpec.describe Leftovers::CLI, type: :cli do
  describe 'leftovers' do
    before do
      allow(Leftovers).to receive(:try_require_cache).and_call_original
      allow(Leftovers).to receive(:try_require_cache).with('bundler').and_return(false)

      with_temp_dir
    end

    context 'with no files' do
      it 'runs' do
        run
        expect(stdout).to have_output <<~STDOUT
          checked 0 files, collected 0 calls, 0 definitions
          \e[32mEverything is used\e[0m
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end

      it "doesn't generate a TODO file" do
        run('--write-todo')
        expect(stdout).to have_output <<~STDOUT
          checked 0 files, collected 0 calls, 0 definitions
          No .leftovers_todo.yml file generated, everything is used
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end

      it 'outputs the version when --version' do
        run '--version'
        expect(stdout).to have_output <<~STDOUT
          #{Leftovers::VERSION}
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end

      it 'outputs no files when --dry-run' do
        run '--dry-run'
        expect(stdout.string).to be_empty
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end

      it 'outputs the files when --help' do
        run '--help'
        expect(stdout).to have_output <<~STDOUT
          Usage: leftovers [options]
                  --[no-]parallel              Run in parallel or not, default --parallel
                  --[no-]progress              Show progress counts or not, default --progress
                  --dry-run                    Output files that will be looked at
                  --write-todo                 Outputs the unused items in a todo file to gradually fix
              -v, --version                    Returns the current version
              -h, --help                       Shows this message
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end
    end

    context 'with a test method defined and unused' do
      before do
        temp_file 'test/bar.rb', <<~RUBY
          def test_method; end
        RUBY
      end

      it 'runs with --write-todo' do
        Timecop.freeze('2021-06-14T22:03:35 UTC')

        run('--no-parallel --write-todo') # so i get consistent order

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 0 calls, 1 definitions
          generated .leftovers_todo.yml.
          running leftovers again will read this file and not alert you to any unused items mentioned in it.

          commit this file so you/your team can gradually address these items while still having leftovers alert you to any newly unused items.
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0

        expect(temp_dir.join('.leftovers_todo.yml').read).to eq(<<~FILE)
          # This file was generated by `leftovers --write-todo`
          # Generated at: 2021-06-14 22:03:35 UTC
          #
          # for instructions on how to address these
          # see https://github.com/robotdana/leftovers/tree/v#{Leftovers::VERSION}/README.md#how-to-resolve

          keep:
            # Not directly called at all:
            - "test_method" # test/bar.rb:1:5 def test_method; end
        FILE

        expect { Psych.safe_load(temp_dir.join('.leftovers_todo.yml').read) }.not_to raise_error
      end
    end

    context 'with files with linked config' do
      before do
        temp_file '.leftovers.yml', <<~YML
          dynamic:
            - name: test_method
              defines:
                argument: 0
                transforms:
                  - original
                  - add_suffix: '?'
        YML

        temp_file 'app/foo.rb', <<~RUBY
          test_method :test
        RUBY
      end

      it 'runs' do
        run

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 1 calls, 1 definitions
          \e[31mNot directly called at all:\e[0m
          \e[36mapp/foo.rb:1:13\e[0m test, test? \e[2mtest_method \e[33m:test\e[0;2m\e[0m

          how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 1
      end

      it 'runs with --write-todo' do
        Timecop.freeze('2021-06-14T22:03:35 UTC')

        run('--no-parallel --write-todo') # so i get consistent order

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 1 calls, 1 definitions
          generated .leftovers_todo.yml.
          running leftovers again will read this file and not alert you to any unused items mentioned in it.

          commit this file so you/your team can gradually address these items while still having leftovers alert you to any newly unused items.
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0

        expect(temp_dir.join('.leftovers_todo.yml').read).to eq(<<~FILE)
          # This file was generated by `leftovers --write-todo`
          # Generated at: 2021-06-14 22:03:35 UTC
          #
          # for instructions on how to address these
          # see https://github.com/robotdana/leftovers/tree/v#{Leftovers::VERSION}/README.md#how-to-resolve

          keep:
            # Not directly called at all:
            - "test" # app/foo.rb:1:13 test_method :test
            - "test?" # app/foo.rb:1:13 test_method :test
        FILE

        expect { Psych.safe_load(temp_dir.join('.leftovers_todo.yml').read) }.not_to raise_error
      end
    end

    context 'with files with unused methods' do
      before do
        temp_file('app/foo.rb', <<~RUBY)
          attr_reader :foo

          def unused_method
            @bar = true
          end
        RUBY
      end

      it 'runs' do
        expect(Parallel).to receive(:each).once.and_call_original # parallel by default

        run

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 2 calls, 3 definitions
          \e[31mNot directly called at all:\e[0m
          \e[36mapp/foo.rb:1:13\e[0m foo \e[2mattr_reader \e[33m:foo\e[0;2m\e[0m
          \e[36mapp/foo.rb:3:5\e[0m unused_method \e[2mdef \e[33munused_method\e[0;2m\e[0m
          \e[36mapp/foo.rb:4:3\e[0m @bar \e[2m\e[33m@bar\e[0;2m = true\e[0m

          how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 1
      end

      it 'runs with --write-todo' do
        Timecop.freeze('2021-06-14T22:03:35 UTC')
        run('--write-todo')

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 2 calls, 3 definitions
          generated .leftovers_todo.yml.
          running leftovers again will read this file and not alert you to any unused items mentioned in it.

          commit this file so you/your team can gradually address these items while still having leftovers alert you to any newly unused items.
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0

        expect(temp_dir.join('.leftovers_todo.yml').read).to eq(<<~FILE)
          # This file was generated by `leftovers --write-todo`
          # Generated at: 2021-06-14 22:03:35 UTC
          #
          # for instructions on how to address these
          # see https://github.com/robotdana/leftovers/tree/v#{Leftovers::VERSION}/README.md#how-to-resolve

          keep:
            # Not directly called at all:
            - "@bar" # app/foo.rb:4:3 @bar = true
            - "foo" # app/foo.rb:1:13 attr_reader :foo
            - "unused_method" # app/foo.rb:3:5 def unused_method
        FILE

        expect { Psych.safe_load(temp_dir.join('.leftovers_todo.yml').read) }.not_to raise_error
      end

      it 'runs with --write-todo and a preexisting TODO file' do
        Timecop.freeze('2021-06-14T22:03:35 UTC')

        todo_file = temp_file('.leftovers_todo.yml')
        run('--write-todo')

        expect(stdout).to have_output <<~STDOUT
          Removing previous .leftovers_todo.yml file

          checked 1 files, collected 2 calls, 3 definitions
          generated .leftovers_todo.yml.
          running leftovers again will read this file and not alert you to any unused items mentioned in it.

          commit this file so you/your team can gradually address these items while still having leftovers alert you to any newly unused items.
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0

        expect(todo_file.read).to eq(<<~FILE)
          # This file was generated by `leftovers --write-todo`
          # Generated at: 2021-06-14 22:03:35 UTC
          #
          # for instructions on how to address these
          # see https://github.com/robotdana/leftovers/tree/v#{Leftovers::VERSION}/README.md#how-to-resolve

          keep:
            # Not directly called at all:
            - "@bar" # app/foo.rb:4:3 @bar = true
            - "foo" # app/foo.rb:1:13 attr_reader :foo
            - "unused_method" # app/foo.rb:3:5 def unused_method
        FILE

        expect { Psych.safe_load(todo_file.read) }.not_to raise_error
      end

      it 'runs with --no-parallel' do
        expect(Parallel).to receive(:each).exactly(0).times

        run('--no-parallel')

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 2 calls, 3 definitions
          \e[31mNot directly called at all:\e[0m
          \e[36mapp/foo.rb:1:13\e[0m foo \e[2mattr_reader \e[33m:foo\e[0;2m\e[0m
          \e[36mapp/foo.rb:3:5\e[0m unused_method \e[2mdef \e[33munused_method\e[0;2m\e[0m
          \e[36mapp/foo.rb:4:3\e[0m @bar \e[2m\e[33m@bar\e[0;2m = true\e[0m

          how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 1
      end

      it 'runs with --parallel' do
        expect(Parallel).to receive(:each).once.and_call_original

        run('--parallel')

        expect(stdout).to have_output <<~STDOUT
          checked 1 files, collected 2 calls, 3 definitions
          \e[31mNot directly called at all:\e[0m
          \e[36mapp/foo.rb:1:13\e[0m foo \e[2mattr_reader \e[33m:foo\e[0;2m\e[0m
          \e[36mapp/foo.rb:3:5\e[0m unused_method \e[2mdef \e[33munused_method\e[0;2m\e[0m
          \e[36mapp/foo.rb:4:3\e[0m @bar \e[2m\e[33m@bar\e[0;2m = true\e[0m

          how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 1
      end

      it 'outputs the version when --version' do
        run '--version'
        expect(stdout).to have_output <<~STDOUT
          #{Leftovers::VERSION}
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end

      it 'outputs the files when --dry-run' do
        run '--dry-run'
        expect(stdout).to have_output <<~STDOUT
          app/foo.rb
        STDOUT
        expect(stderr.string).to be_empty
        expect(exitstatus).to be 0
      end

      context 'with tests' do
        before do
          temp_file 'test/foo.rb', <<~RUBY
            expect(unused_method).to eq foo
            self.instance_variable_get(:@bar) == true
          RUBY
        end

        it 'runs' do
          run

          expect(stdout.string).to eq(
            <<~STDOUT
              \e[2Kchecked 1 files, collected 2 calls, 3 definitions\r\e[2Kchecked 2 files, collected 10 calls, 3 definitions\r\e[2Kchecked 2 files, collected 10 calls, 3 definitions\r
              \e[2K\e[31mOnly directly called in tests:\e[0m
              \e[2K\e[36mapp/foo.rb:1:13\e[0m foo \e[2mattr_reader \e[33m:foo\e[0;2m\e[0m
              \e[2K\e[36mapp/foo.rb:3:5\e[0m unused_method \e[2mdef \e[33munused_method\e[0;2m\e[0m
              \e[2K\e[36mapp/foo.rb:4:3\e[0m @bar \e[2m\e[33m@bar\e[0;2m = true\e[0m
              \e[2K
              how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
            STDOUT
          ).or(
            eq(
              <<~STDOUT
                \e[2Kchecked 1 files, collected 8 calls, 0 definitions\r\e[2Kchecked 2 files, collected 10 calls, 3 definitions\r\e[2Kchecked 2 files, collected 10 calls, 3 definitions\r
                \e[2K\e[31mOnly directly called in tests:\e[0m
                \e[2K\e[36mapp/foo.rb:1:13\e[0m foo \e[2mattr_reader \e[33m:foo\e[0;2m\e[0m
                \e[2K\e[36mapp/foo.rb:3:5\e[0m unused_method \e[2mdef \e[33munused_method\e[0;2m\e[0m
                \e[2K\e[36mapp/foo.rb:4:3\e[0m @bar \e[2m\e[33m@bar\e[0;2m = true\e[0m
                \e[2K
                how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
              STDOUT
            )
          )
          expect(stderr.string).to be_empty
          expect(exitstatus).to be 1
        end

        it 'runs with suppressed progress' do
          run('--no-progress')

          expect(stdout.string).to eq <<~STDOUT
            \e[2Kchecked 2 files, collected 10 calls, 3 definitions\r
            \e[2K\e[31mOnly directly called in tests:\e[0m
            \e[2K\e[36mapp/foo.rb:1:13\e[0m foo \e[2mattr_reader \e[33m:foo\e[0;2m\e[0m
            \e[2K\e[36mapp/foo.rb:3:5\e[0m unused_method \e[2mdef \e[33munused_method\e[0;2m\e[0m
            \e[2K\e[36mapp/foo.rb:4:3\e[0m @bar \e[2m\e[33m@bar\e[0;2m = true\e[0m
            \e[2K
            how to resolve: \e[32m#{Leftovers.resolution_instructions_link}\e[0m
          STDOUT
          expect(stderr.string).to be_empty
          expect(exitstatus).to be 1
        end

        it 'runs with --write-todo' do
          Timecop.freeze('2021-06-14T22:03:35 UTC')
          temp_file 'test/bar.rb', <<~RUBY
            def test_method; end
          RUBY

          run('--write-todo') # so i get consistent order

          expect(stdout).to have_output <<~STDOUT
            checked 3 files, collected 10 calls, 4 definitions
            generated .leftovers_todo.yml.
            running leftovers again will read this file and not alert you to any unused items mentioned in it.

            commit this file so you/your team can gradually address these items while still having leftovers alert you to any newly unused items.
          STDOUT
          expect(stderr.string).to be_empty
          expect(exitstatus).to be 0

          expect(temp_dir.join('.leftovers_todo.yml').read).to eq(<<~FILE)
            # This file was generated by `leftovers --write-todo`
            # Generated at: 2021-06-14 22:03:35 UTC
            #
            # for instructions on how to address these
            # see https://github.com/robotdana/leftovers/tree/v#{Leftovers::VERSION}/README.md#how-to-resolve

            test_only:
              # Only directly called in tests:
              - "@bar" # app/foo.rb:4:3 @bar = true
              - "foo" # app/foo.rb:1:13 attr_reader :foo
              - "unused_method" # app/foo.rb:3:5 def unused_method

            keep:
              # Not directly called at all:
              - "test_method" # test/bar.rb:1:5 def test_method; end
          FILE

          expect { Psych.safe_load(temp_dir.join('.leftovers_todo.yml').read) }.not_to raise_error
        end
      end

      context 'with some test' do
        before do
          temp_file 'test/foo.rb', <<~RUBY
            expect(unused_method).to eq foo
          RUBY
        end

        it 'runs with --write-todo' do
          Timecop.freeze('2021-06-14T22:03:35 UTC')
          temp_file 'test/bar.rb', <<~RUBY
            def test_method; end
          RUBY

          run('--write-todo') # so i get consistent order

          expect(stdout).to have_output <<~STDOUT
            checked 3 files, collected 7 calls, 4 definitions
            generated .leftovers_todo.yml.
            running leftovers again will read this file and not alert you to any unused items mentioned in it.

            commit this file so you/your team can gradually address these items while still having leftovers alert you to any newly unused items.
          STDOUT
          expect(stderr.string).to be_empty
          expect(exitstatus).to be 0

          expect(temp_dir.join('.leftovers_todo.yml').read).to eq(<<~FILE)
            # This file was generated by `leftovers --write-todo`
            # Generated at: 2021-06-14 22:03:35 UTC
            #
            # for instructions on how to address these
            # see https://github.com/robotdana/leftovers/tree/v#{Leftovers::VERSION}/README.md#how-to-resolve

            test_only:
              # Only directly called in tests:
              - "foo" # app/foo.rb:1:13 attr_reader :foo
              - "unused_method" # app/foo.rb:3:5 def unused_method

            keep:
              # Not directly called at all:
              - "@bar" # app/foo.rb:4:3 @bar = true
              - "test_method" # test/bar.rb:1:5 def test_method; end
          FILE

          expect { Psych.safe_load(temp_dir.join('.leftovers_todo.yml').read) }.not_to raise_error
        end
      end
    end
  end
end
