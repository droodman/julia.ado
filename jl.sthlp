{smcl}
{* *! jl 1.1.0 8nov2024}{...}
{help jl:jl}
{hline}{...}

{title:Title}

{pstd}
Bridge to Julia{p_end}

{title:Syntax}

{phang}
{cmd:jl}: {it:juliaexpr}

{phang}
{cmd:_jl}: {it:juliaexpr}

{phang2}
where {it:juliaexpr} is an expression to be evaluated in Julia.

{phang}
{cmd:jl} {it:subcommand} [{varlist}], [{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt start}}Start Julia, optionally setting number of threads{p_end}
{synopt:{opt use}}Load Julia DataFrame to current Stata data set{p_end}
{synopt:{opt save}}Save current data set to Julia DataFrame{p_end}
{synopt:{opt PutVarsToDF}}Copy Stata variables to Julia DataFrame{p_end}
{synopt:{opt GetVarsFromDF}}Copy Stata variables from Julia DataFrame, mapping NaN to missing{p_end}
{synopt:{opt PutVarsToMat}}Copy Stata variables to Julia matrix{p_end}
{synopt:{opt GetVarsFromMat}}Copy Stata variables from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt PutMatToMat}}Copy Stata matrix to Julia matrix, mapping missing to NaN{p_end}
{synopt:{opt GetMatFromMat}}Copy Stata matrix from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt SetEnv}}Switch to named package environment{p_end}
{synopt:{opt GetEnv}}Get name of current package environment{p_end}
{synopt:{opt AddPkg}}Install Julia package if not installed, or update if version below threshold{p_end}
{synopt:{opt version}}Get version of installed {cmd:jl} package{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{cmd:jl start} [, {cmdab:t:hreads(}{it:integer} or {cmd:auto)}]{p_end}

{phang}{cmd:jl use} {it:dataframename}, [{opt clear}]{p_end}
{phang}-or-{p_end}
{phang}{cmd:jl use} {varlist} {cmd:using} {it:dataframename}, [{opt clear}]{p_end}

{phang}
{cmd:jl save} [{it:dataframename}], [{opt nolab:el} {opt nomiss:ing} {opt double:only}]

{phang}
{cmd:jl PutVarsToDF} [{varlist}] {ifin}, [{opt dest:ination(string)} {opt col:s(string)} {opt nolab:el} {opt nomiss:ing} {opt double:only}]

{phang}
{cmd:jl GetVarsFromDF} {varlist} {ifin}, [{opt cols(string)} {opt source(string)} {opt replace} {opt nomiss:ing}]

{phang}
{cmd:jl PutVarsToMat} [{varlist}] {ifin}, {opt dest:ination(string)}

{phang}
{cmd:jl GetVarsFromMat} {varlist} {ifin}, {opt source(string)} [replace]

{phang}
{cmd:jl PutMatToMat} {it:matname}, [{opt dest:ination(string)}]

{phang}
{cmd:jl GetMatFromMat} {it:matname}, [{opt source(string)}]

{phang}
{cmd:jl SetEnv} [{it:name}]

{phang}
{cmd:jl GetEnv}

{phang}
{cmd:jl AddPkg} {it:name}, [{opt min:ver(string)}]

{phang}
{cmd:jl version}


{marker description}{...}
{title:Description}

{pstd}
{cmd:jl} gives access from the Stata prompt to the free programming language Julia. It provides three
sets of tools:

{p 4 7 0}
1. {it:The {cmd:jl:} prefix command, which allows you to send commands to Julia and see the results.} (But results
are suppressed for lines ending with ";".) Example: 
{cmd:jl: "Hellow world!"}. Typing {cmd:jl:} or {cmd:jl} by itself starts an interactive mode, in which
multiple lines can be typed. This mode stops when the user types {cmd:exit()}.

{p 4 7 0}
2. {it:Subcommands, listed above, for high-speed copying of data between Julia and Stata, managing installation of Julia packages.}

{p 4 7 0}
3. {it:A library of Julia functions to allow reading and writing of Stata variables, macros, matrices, and scalars.} Most of
the functions hew closely to those in the {browse "https://www.stata.com/plugins":Stata plugin interface}. For example,
{cmd:jl: SF_vdata(1, 2)} getsts the value in the second row of the first variable in the Stata data set. Some
are higher level: st_data("price mpg") returns a two-column matrix with the contents of those variables.

{pstd}
Because Julia does just-in-time-compilation, {it:Julia-based commands take longer on first use in a Stata session and even longer on first use on a given machine.}

{pstd}
The interactive mode does not work in do files. That is, while you can begin a Mata or Python
block in a do file withe the {cmd:mata} or {cmd:python} command, you cannot do the same for 
Julia. You can work around that limitation. You can put several commands in one
line, separating them with semicolons. And you can break what are logically single lines into many, using Stata's
continuation token, "///":{p_end}

{pmore}{inp} jl: s = 0; for i in 1:10 s += i end; s {p_end}

{pmore}{inp} jl: s = 0; {space 7}/// {p_end}
{pmore}{inp} {space 4}for i in 1:10 /// {p_end}
{pmore}{inp} {space 8}s += i {space 3}/// {p_end}
{pmore}{inp} {space 4}end; {space 9}/// {p_end}
{pmore}{inp} {space 4}s{p_end}

{pstd}
The {cmd:jl start} command is often not needed. If it is not used, then Julia will be automatically started anyway the first time it is called in a Stata 
session. The one reason to call {cmd:jl start} is to control the number of CPU threads available to Julia, through the {opt t:hreads()} option. Many Julia 
programs exploit multithreading for speed. In Windows and Linux, but not macOS, you can also control the number of threads by editing the JULIA_NUM_THREADS 
environment variable. {cmd:jl start} will have no effect unless it comes before every other {cmd:jl} command in a Stata session, and before any use of
packages such as {cmd:reghdfejl} and {cmd:boottest} that call {cmd:jl}. For more, see {help jl##threads:section on threads below}. You
do not need Stata/MP to run mulithreaded Julia code.

{pstd}
The data-copying subcommands come in high- and low-level variants. The high-level {cmd:jl use} and {cmd:jl save} subcommands have similar syntax
to Stata's {help use} and {help save}, but copy to and from Julia DataFrames. Unlike the low-level {cmd:jl GetVarsFromDF}, {cmd:jl use}
will clear the current data set if the {opt clear} option is included, and ensure that the new data set has enough rows to receive all the data.

{pstd}
The low-level routines give more options to improve performance, which are 
useful when using {cmd:jl} to write a Julia back end for a Stata package. By default, the {cmd:jl PutVarsToDF} subcommand will map Stata data columns
to Julia DataFrame columns of corresponding type, and mark all destination columns to allow missing values. {cmd:jl GetVarsFromDF} does
something similar in the other direction. {cmd:PutVarsToDF}'s {opt nomiss:ing} option increases speed and is appropriate for variables known to contain no missing values. 
Another time-saving option, {opt double:only}, causes {cmd:jl PutVarsToDF} to map all numeric Stata {help data_types:data types}, to double-precision numbers--called {cmd:double} in Stata
and {cmd:Float64} in Julia. Treatment of strings is then undefined. Without this option, the target
columns will have the same types as the source columns.

{pstd}
When copying to Julia, any existing DataFrame or matrix of the same name is overwritten.

{pstd}
The subcommands mapping between Stata data and Julia DataFrames translate between Stata variables with value labels and Julia categorical vectors. However,
the mapping from Stata to Julia is computationally inefficient--all values are replaced with their labels before conversion to type CategoricalVector, and
can be prevented with the {opt nolab:el} option.

{pstd}
The {cmd:SetEnv} subcommand switches to a package environment associated with the supplied 
name. This is useful when writing Julia-based Stata programs that need to install certain Julia
packages. Switching to a dedicated environment minimizes version conflicts with packages
downloaded for other purposes. The directory used for the dedicated environment will be a 
subdirectory of Julia's default package environment directory, for example,
"`~/.julia/environments/v1.10/MyEnvironment". It will be created if it does not exist. If new,
it will only have the DataFrames package. Calling {cmd:SetEnv} without any arguments reverts to
the default package environment.

{pstd}
The {cmd:GetEnv} displays the name and location of the current package environment and
saves the results as r() macros.

{pstd}
The {cmd:AddPkg} subcommand updates a package to the latest version in Julia's general registry if the package is not installed at all, or if
the current version is below that set by the optional {opt min:ver()} option. It operates within
the current Julia package environment. So {cmd:jl AddPkg ...} followed by {cmd:jl SetEnv ...} will generally
have a different effect than the same commands in the opposite order.


{marker installation}{...}
{title:Installing Julia}

{pstd}
This package is designed for 64-bit Windows, Linux, and macOS, the last on an Intel or Apple CPU. It requires 
Julia 1.11.1 or higher. As documented {browse "https://github.com/JuliaLang/juliaup#installation":here}, the easiest way to
install it in Windows is from the {browse "https://apps.microsoft.com/detail/9NJNWW8PVKMN":Microsoft Store}; and the 
easiest way to install it in Linux and macOS is with this shell command from inside Stata, which is clickable:

{pin}{stata "! curl -fsSL https://install.julialang.org | sh -s -- -y"}

{pstd}
On Intel Macs, 
{cmd:jl} seems to require at least macOS 11 (Big Sur) or 12 (Monterey). On computers not officially supported by those editions, one can use 
the {browse "https://dortania.github.io/OpenCore-Legacy-Patcher/":OpenCore Legacy Patcher} to upgrade--at your own risk.

{pstd}
After installing Julia, restart Stata for good measure.

{pstd} On first use, {cmd:jl} will attempt to install the Julia packages DataFrames.jl and CategoricalArrays.jl. That can take a minute.


{title:Installing the JuliaMono font}

{pstd}The {browse "https://juliamono.netlify.app":JuliaMono} font is a free, monospaced font that works well in Stata and includes
Unicode characters that often appear in Julia output, such as {browse "https://www.compart.com/en/unicode/U+22EE":vertical} and 
{browse "https://www.compart.com/en/unicode/U+22F1":diagonal} ellipses. You can 
{browse "https://github.com/cormullion/juliamono/releases":download the TTF file}, install it, and 
{browse "https://www.stata.com/manuals/gsm17.pdf":configure Stata to use it}.


{marker threads}{...}
{title:Setting the number of CPU threads}

{pstd}
Many Julia programs exploit multithreading. However, Julia is typically installed to only allow one thread by default. In Windows and Linux, and in
macOS if you willing to endure a little inconvenience (see below), you can
permanently override this default by editing your operating system's JULIA_NUM_THREADS environment variable. Set it to an integer such as 4 or 8,
or to "auto" to let Julia decide. On CPUs with hyperthreading or efficiency (E) cores as well as performance (P) cores,
the optimal number is usually not the maximum the CPU technically supports. A good guess is the number of P cores.

{pstd}
How to set this variable depends on your operating system:

{p 4 6 0}
* In Windows, use the Environment Variables control panel to add JULIA_NUM_THREADS. One route to that dialog box is to press the Windows logo
button on the keyboard and type "environment variables".

{p 4 6 0}
* In Linux, add "export JULIA_NUM_THREADS=8" (as an example) to the text file "~/.bashrc". Restart the terminal window.

{p 4 6 0}
* Similarly, in macOS, add such a line to "~/.zshenv".

{pstd}
Now, in macOS, editing ~/.zshenv will have no effect unless you launch Stata from a terminal window instead of the graphical desktop. To do so:

{p 4 6 0}
* Type Command-spacebar to launch Spotlight Search, then type "Stata" and observe the autocompletion to determine the exact name of the Stata app on your
system. For example, if you have Stata/MP, you should see "StataMP".

{p 4 6 0}
* Clear the Spotlight Search box and then type "terminal" and the return key to launch a terminal window.

{p 4 6 0}
* Run the command line "open -a [Stata app name]" where [Stata app name] is, for example, "StataMP".

{pstd}
An alternative way to set the number of threads is to explicitly launch Julia inside Stata with {cmd:jl start, }{opt threads(string)} where {it:string} is a positive
integer or {cmd:auto}. To have any effect, this command must precede any other invocation of {cmd:jl} in a Stata session, 
and any other invocation of Julia-calling commands such as {cmd:reghdfejl} and {cmd:boottest}.

{pstd}
To determine how many threads are available, type "{stata "jl: Threads.nthreads()"}" at the Stata prompt.


{title:Options}

{pstd}
In the data-copying subcommands, the {varlist}'s and {opt matname}'s before the commas always
refer to Stata variables or matrices. If a {varlist} is omitted where it is optional,
the variable list will default to {cmd:*}, i.e., all variables in the current data frame in 
their current order.

{pstd}
The options after the comma in these subcommands refer to Julia objects. {opt dest:ination()}
and {opt source()} name the Julia matrix or DataFrame to be written to or from. When
a DataFrame name is not provided, it defaults to {cmd:df}. The {opt cols()} option specifies the 
DataFrame columns to be copied to or from. It defaults to the Stata {varlist} before the comma.

{pstd}
Destination Stata matrices and Julia matrices and DataFrames are entirely replaced. Destination Stata
variables will be created or, if {opt replace} is specified, overwritten, subject to any
{ifin} restriction.

{pstd}
The {cmd:_jl:} prefix command is for programmers. It works the same as {cmd:jl:}, except that for the sake of speed it disables
certain features of {cmd:jl:} that enhance the interactive Julia experience within Stata. These include checking whether Julia is
started and starting it if not, showing output from {cmd:print()}
and other commands, not generating syntax errors partway through multi-line code blocks such as for loops, and 
{browse "https://docs.julialang.org/en/v1/manual/variables-and-scoping/#local-scope":interpreting soft-scoped assignments as if in interactive mode}. The 
time savings from {cmd:_jl:} can be small in absolute terms (~0.01 seconds per call). But it adds up in a program that issues many
Julia commands. Warning: {cmd:_jl} can crash Stata if it is called before Julia is started via a {cmd:jl} command!


{title:Stored results}

{pstd}
{cmd:jl:} stores the output in the macro {cmd:r(ans)}. {cmd:jl version} returns the version number of the installed {cmd:jl} package in r(version).


{title:Stata interface functions}

{pstd}
The {cmd:julia.ado} package automatically loads a Julia module that gives access to the 
{browse "https://www.stata.com/plugins":Stata Plugin Interface} (SPI), which see for more information on 
syntax. The functions in the module allow one to read and write
Stata objects from Julia. They can be roughly divided into low- and high-level groups. The low-level
functions closely mimic the foundational SPI functions, which let you, for example, determine
the size of the data set and read and write individual data points. The high-level functions
work similarly to the Mata functions they are named after: {cmd:st_global()}, {cmd:st_local()}, {cmd:st_matrix()}, {cmd:st_data()}, and 
{cmd:st_view()}. In particular, {cmd:st_view()} lets you treat one or more Stata variables as a matrix, which can be read
and written with Julia commands.

{synoptset 59 tabbed}{...}
{synopthdr:Function}
{synoptline}
{synopt:{bf:SF_nobs()}}Number of observations in Stata data set{p_end}
{synopt:{bf:SF_nvar()}}Number of variables{p_end}
{synopt:{bf:SF_var_is_string(i::Int)}}Whether variable i is string{p_end}
{synopt:{bf:SF_var_is_strl(i::Int)}}Whether variable i is a strL{p_end}
{synopt:{bf:SF_var_is_binary(j::Int, i::Int)}}Whether observation j of variable i is a binary strL{p_end}
{synopt:{bf:SF_sdatalen(j::Int, i::Int)}}String length of variable i, observation j{p_end}
{synopt:{bf:SF_is_missing()}}Whether a Float64 value is Stata missing{p_end}
{synopt:{bf:SV_missval()}}Stata floating-point value for missing{p_end}
{synopt:{bf:SF_vstore(j::Int, i::Int, val::Real)}}Set observation j of variable i to val (numeric){p_end}
{synopt:{bf:SF_sstore(j::Int, i::Int, s::String)}}Set observation j of variable i to s (string) {p_end}
{synopt:{bf:SF_vdata(j::Int, i::Int)}}Get observation j of variable i (numeric){p_end}
{synopt:{bf:SF_sdata(j::Int, i::Int)}}Get observation j of variable i (string){p_end}
{synopt:{bf:SF_macro_save(mac::String, tosave::String)}}Set macro value{p_end}
{synopt:{bf:SF_macro_use(mac::String)}}Get macro mac{p_end}
{synopt:{bf:SF_scal_save(scal::String, val::Real)}}Set scalar value{p_end}
{synopt:{bf:SF_scal_use(scal::String)}}Get scalar scal{p_end}
{synopt:{bf:SF_row(mat::String)}}Number of rows of matrix mat{p_end}
{synopt:{bf:SF_col(mat::String)}}Number of columns of matrix mat{p_end}
{synopt:{bf:SF_mat_store(mat::String, i::Int, j::Int, val::Real)}}mat[i,j] = val{p_end}
{synopt:{bf:SF_mat_el(mat::String, i::Int, j::Int)}}Get mat[i,j]{p_end}
{synopt:{bf:SF_display(s::String)}}Print to Stata results window{p_end}
{synopt:{bf:SF_error(s::String)}}Print error to Stata results window{p_end}

{synopt:{bf:st_nobs()}}Number of observations in Stata data set; same as SF_nobs(){p_end}
{synopt:{bf:st_nvar()}}Number of Stata variables; same as SF_nvar(){p_end}
{synopt:{bf:st_varindex(s::String)}}Index in data set of variable named s{p_end}
{synopt:{bf:st_global(mac::String)}}Get global macro mac{p_end}
{synopt:{bf:st_global(mac::String, tosave::String)}}Set global macro mac{p_end}
{synopt:{bf:st_local(mac::String, tosave::String)}}Set local macro mac{p_end}
{synopt:{bf:st_numscalar(scal::String)}}Get scalar scal; same as SF_scal_use(){p_end}
{synopt:{bf:st_numscalar(scal::String, val::Real)}}Set scalar scal; same as SF_scal_save(){p_end}
{synopt:{bf:st_matrix(matname::String)}}Get numeric Stata matrix{p_end}
{synopt:{bf:st_matrix(matname::String, jlmat::Matrix)}}Put Julia matrix in pre-existing Stata matrix{p_end}
{synopt:{bf:st_data(varnames::String)}}Get Stata variables in space-delimited list, as matrix{p_end}
{synopt:{bf:st_data(varnames::Vector{<:String})}}Get Stata variables in string vector, as matrix{p_end}
{synopt:{bf:st_data(varnames::String, sample::Vector{Bool})}}Get Stata variables, with sample restriction, as matrix{p_end}
{synopt:{bf:st_data(varnames::Vector{<:String}, sample::Vector{Bool})}}Get Stata variables, with sample restriction, as matrix{p_end}
{synopt:{bf:st_view(varnames::String)}}Get Stata variables in space-delimited list, as view{p_end}
{synopt:{bf:st_view(varnames::Vector{<:String})}}Get Stata variables in string vector, as view{p_end}
{synopt:{bf:st_view(varnames::String, sample::Vector{Bool})}}Get Stata variables, with sample restriction, as view{p_end}
{synopt:{bf:st_view(varnames::Vector{<:String}, sample::Vector{Bool})}}Get Stata variables, with sample restriction, as view{p_end}
{synoptline}
{p2colreset}{...}

{pstd}
Used with {cmd:jl}, but not {cmd:_jl}, {cmd:st_local()} allows one to {it:write} locals. One-line {cmd:jl:} and {cmd:_jl:} commands
can access locals by quoting them, such as with {cmd:jl: X = st_data("`varnames'")}


{title:Author}

{p 4}David Roodman{p_end}
{p 4}david@davidroodman.com{p_end}


{title:Acknowledgements}

{pstd}
This project was inspired by James Fiedler's {browse "https://ideas.repec.org/c/boc/bocode/s457688.html":Python plugin for Stata} (as perhaps
was Stata's support for Python).


