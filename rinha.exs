[command, file] = System.argv()

case command do
  "transpile" -> Rinha.print_transpiled(file)
  "run" -> Rinha.run(file)
  "ir" -> IO.inspect(Rinha.file_to_ir(file))
end
