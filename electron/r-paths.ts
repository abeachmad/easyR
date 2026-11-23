import { app } from 'electron'
import fs from 'node:fs'
import path from 'node:path'

export function getREngineDir(): string {
  return app.isPackaged
    ? path.join(process.resourcesPath, 'r-engine')
    : path.join(app.getAppPath(), 'r-engine')
}

export function getModulesDir(): string {
  return app.isPackaged
    ? path.join(process.resourcesPath, 'modules')
    : path.join(app.getAppPath(), 'modules')
}

export function resolveRscriptExecutable(): string | null {
  if (process.platform === 'win32') {
    const roots = [
      process.env['ProgramFiles'],
      process.env['ProgramFiles(x86)'],
      'C:\\Program Files',
    ].filter((value): value is string => Boolean(value))
    for (const root of roots) {
      const rRoot = path.join(root, 'R')
      if (!fs.existsSync(rRoot)) continue
      const versions = fs.readdirSync(rRoot).sort().reverse()
      for (const version of versions) {
        const candidates = [
          path.join(rRoot, version, 'bin', 'x64', 'Rscript.exe'),
          path.join(rRoot, version, 'bin', 'Rscript.exe'),
        ]
        const found = candidates.find((candidate) => fs.existsSync(candidate))
        if (found) return found
      }
    }
  }
  const candidates = process.platform === 'darwin'
    ? ['/usr/bin/Rscript', '/opt/homebrew/bin/Rscript', '/Library/Frameworks/R.framework/Resources/bin/Rscript', 'Rscript']
    : ['/usr/bin/Rscript', '/usr/local/bin/Rscript', 'Rscript']
  return candidates.find((candidate) => candidate === 'Rscript' || fs.existsSync(candidate)) ?? null
}
