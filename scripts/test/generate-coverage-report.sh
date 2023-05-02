forge coverage --no-match-path "./test/mocks/*" --report lcov

lcov --remove ./lcov.info -o ./lcov.info.pruned '/test/mocks/*' 'test/mocks/*'

genhtml lcov.info.pruned --output-directory coverage

open coverage/index.html