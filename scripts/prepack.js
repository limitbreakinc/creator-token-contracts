#!/usr/bin/env node

// This script removes the build artifacts of ignored contracts.

const fs = require('fs');
const path = require('path');
const match = require('micromatch');

async function main() {
  fs.mkdirSync("build/contracts", { recursive: true });
  const jsonFiles = [];
  await fromDir('./artifacts/contracts', '.json', jsonFiles);
  for(let i = 0; i < jsonFiles.length; i++) {
      if(jsonFiles[i].includes("dbg.json")) {
          continue;
      }
      
      await fs.copyFileSync(jsonFiles[i], `build/contracts/${path.basename(jsonFiles[i])}`);
  }

  removeIgnoredArtifacts();
}

async function fromDir(startPath, filter, jsonFiles) {

    if (!fs.existsSync(startPath)) {
        console.log("no dir ", startPath);
        return;
    }

    var files = fs.readdirSync(startPath);
    for (var i = 0; i < files.length; i++) {
        var filename = path.join(startPath, files[i]);
        var stat = fs.lstatSync(filename);
        if (stat.isDirectory()) {
            fromDir(filename, filter, jsonFiles); //recurse
        } else if (filename.endsWith(filter)) {
            jsonFiles.push(filename);
        };
    };
};

function removeIgnoredArtifacts() {
    function readJSON (path) {
        return JSON.parse(fs.readFileSync(path));
      }
      
      const pkgFiles = readJSON('package.json').files;
      
      // Get only negated patterns.
      const ignorePatterns = pkgFiles
        .filter(pat => pat.startsWith('!'))
      // Remove the negation part. Makes micromatch usage more intuitive.
        .map(pat => pat.slice(1));
      
      const ignorePatternsSubtrees = ignorePatterns
      // Add **/* to ignore all files contained in the directories.
        .concat(ignorePatterns.map(pat => path.join(pat, '**/*')))
        .map(p => p.replace(/^\//, ''));
      
      const artifactsDir = 'build/contracts';
      const buildinfo = 'artifacts/build-info';
      const filenames = fs.readdirSync(buildinfo);
      
      let n = 0;
      
      for (const filename of filenames) {
        const solcOutput = readJSON(path.join(buildinfo, filename)).output;
        for (const sourcePath in solcOutput.contracts) {
          const ignore = match.any(sourcePath, ignorePatternsSubtrees);
          if (ignore) {
            for (const contract in solcOutput.contracts[sourcePath]) {
              fs.unlinkSync(path.join(artifactsDir, contract + '.json'));
              n += 1;
            }
          }
        }
      }
      
      console.error(`Removed ${n} mock artifacts`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});