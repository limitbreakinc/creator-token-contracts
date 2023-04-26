forge coverage --report lcov

genhtml lcov.info --output-directory coverage

open coverage/index.html