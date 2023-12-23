# Examples of plugin compilation

## Windows
It is built in a Visual Studio project, elements of which are included in this package. The package should include
the three files in the [cpp folder](https://github.com/droodman/julia.ado/tree/master/cpp). In the project's Properties|C/C++|General|Additional Include Directories, add 
the Julia include directory, such as
`C:\Users\drood\.julia\juliaup\julia-1.9.4+0.x64.w64.mingw32\include\julia`.

## Linux
```
JULIA_DIR=/home/droodman/.julia/juliaup/julia-1.9.4+0.x64.linux.gnu
g++ -shared -fPIC -DSYSTEM=OPUNIX stplugin.c julia.ado.cpp -o jl.plugin -I$JULIA_DIR/include/julia
```

## macOS
```
JULIA_DIR=/Applications/Julia-1.9.app/Contents/Resources/julia
g++ -bundle -fPIC -DSYSTEM=APPLEMAC stplugin.c julia.ado.cpp -o jl.plugin -I$JULIA_DIR/include/julia -std=c++11
```
