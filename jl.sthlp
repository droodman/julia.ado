{smcl}
{* *! jl 0.10.0 3mar2024}{...}
{help jl:jl}
{hline}{...}

{title:Title}

{pstd}
Bridge to Julia{p_end}

{title:Syntax}

{phang}
{cmd:jl} [, {cmdab:qui:etly} {cmdab:inter:ruptible}]: {it:juliaexpr}

{phang2}
where {it:juliaexpr} is an expression to be evaluated in Julia.

{phang}
{cmd:jl} {it:subcommand} [{varlist}], [{it:options}]

{synoptset 22 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt use}}Load Julia DataFrame to current Stata data set{p_end}
{synopt:{opt save}}Save current data set to Julia DataFrame{p_end}
{synopt:{opt PutVarsToDF}}Copy Stata variables to Julia DataFrame{p_end}
{synopt:{opt GetVarsFromDF}}Copy Stata variables from Julia DataFrame, mapping NaN to missing{p_end}
{synopt:{opt PutVarsToMat}}Copy Stata variables to Julia matrix{p_end}
{synopt:{opt GetVarsFromMat}}Copy Stata variables from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt PutMatToMat}}Copy Stata matrix to Julia matrix, mapping missing to NaN{p_end}
{synopt:{opt GetMatFromMat}}Copy Stata matrix from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt SetEnv}}Switch to named package environment{p_end}
{synopt:{opt AddPkg}}Install Julia package if not installed, or update if version below threshold{p_end}
{synoptline}
{p2colreset}{...}

{phang}{cmd:jl use} {it:dataframename}, [{opt clear}]{p_end}
{phang}-or-{p_end}
{phang}{cmd:jl use} [{varlist}] {cmd:using} {it:dataframename}, [{opt clear}]{p_end}

{phang}
{cmd:jl save} {it:dataframename}, [{opt nolab:el} {opt nomiss:ing} {opt double:only}]

{phang}
{cmd:jl PutVarsToDF} [{varlist}] {ifin}, [{opt dest:ination(string)} {opt col:s(string)} {opt nomiss:ing} {opt double:only}]

{phang}
{cmd:jl GetVarsFromDF} {varlist} {ifin}, [{opt cols(string)} {opt source(string)} {opt replace} {opt nomiss:ing}]

{phang}
{cmd:jl PutVarsToMat} [{varlist}] {ifin}, {opt dest:ination(string)}

{phang}
{cmd:jl GetVarsFromMat} {varlist} {ifin}, {opt source(string)}

{phang}
{cmd:jl PutMatToMat} {it:matname}, [{opt dest:ination(string)}]

{phang}
{cmd:jl GetMatFromMat} {it:matname}, [{opt source(string)}]

{phang}
{cmd:jl SetEnv} {it:name}

{phang}
{cmd:jl AddPkg} {it:name}, [{opt min:ver(string)}]


{marker description}{...}
{title:Description}

{pstd}
{cmd:jl} gives access from the Stata prompt to the free programming language Julia. It provides three
sorts of tools:

{p 4 7 0}
1. The {cmd:jl:} prefix command, which allows you to send commands to Julia and see the results. Example: {cmd:jl: 1+1}.

{p 4 7 0}
2. Subcommands, listed above, for high-speed copying of data between Julia and Stata, as well as for installation of Julia packages.

{p 4 7 0}
3. An automatically loaded library of Julia functions to allow reading and writing of Stata variables, macros, matrices, and scalars. These
functions hew closely to those in the {browse "https://www.stata.com/plugins":Stata Plugin Interface}. For example,
{cmd:jl: SF_macro_save("a", "3")} is equivalent to {cmd:global a 3}.

{pstd}
Because Julia does just-in-time-compilation, {it:Julia-based commands take longer on first use and even longer on first installation.}

{pstd}
The {cmd:jl:} prefix only accepts single-line expressions. But in a .do or .ado file, you can stretch that limit:{p_end}

{pmore}{inp} jl: local s = 0; for i in 1:10 s += i end; s {p_end}

{pmore}{inp} jl: {space 14}/// {p_end}
{pmore}{inp} {space 4}local s = 0; {space 1}/// {p_end}
{pmore}{inp} {space 4}for i in 1:10 /// {p_end}
{pmore}{inp} {space 8}s += i {space 3}/// {p_end}
{pmore}{inp} {space 4}end; {space 9}/// {p_end}
{pmore}{inp} {space 4}s{p_end}

{pstd}
The data-copying subcommands come in high- and low-level variants. The high-level {cmd:jl use} and {cmd:jl save} subcommands have similar syntax
to Stata's {help use} and {help save}, but copy to and from Julia DataFrames. Unlike {cmd:jl GetVarsFromDF}, {cmd:jl use}
will clear the current data set if the {opt clear} option is included, and ensure that the new data set has enough rows to receive all the data.

{pstd}
The low-level routines give more control over data copying and include options to improve performance that are 
useful when using {cmd:jl} to write a Stata program. By default, the {cmd:jl PutVarsToDF} subcommand will map Stata data columns
to Julia DataFrame columns of corresponding type, and mark all destination columns to allow missing values. {cmd:jl GetVarsFromDF} does
something similar in the other direction. {cmd:PutVarsToDF}'s {opt nomiss:ing} option increases speed and is appropriate for variables known to contain no missing values. 
Another time-saving option, {opt double:only}, causes {cmd:jl PutVarsToDF} to map all numeric Stata {help data_types:data types}, to double-precision numbers--called {cmd:double} in Stata
and {cmd:Float64} in Julia. (Treatment of strings is then undefined.)

{pstd}
When copying to Julia, any existing DataFrame of the same name is automatically overwritten.

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
it will only have the DataFrames package.

{pstd}
The {cmd:AddPkg} subcommand updates a package to the latest version in Julia's general registry if the package is not installed at all, or if
the current version is below that set by the optional {opt min:ver()} option. It operates within
the current Julia package environment. So {cmd:jl AddPkg ...} followed by {cmd:jl SetEnv ...} will generally
have a different effect than the same commands in the opposite order.


{marker installation}{...}
{title:Installing Julia}

{pstd}
This package is designed for 64-bit Windows, Linux, and macOS, the last on an Intel or Apple CPU. It requires 
Julia 1.9.4 or higher. As documented {browse "https://github.com/JuliaLang/juliaup#installation":here}, the easiest way to
install it in Windows is from the {browse "https://apps.microsoft.com/detail/9NJNWW8PVKMN":Microsoft Store}; and the 
easiest way to install it in Linux and macOS is with the shell command:

{pin}{cmd:curl -fsSL https://install.julialang.org | sh}

{pstd}
On Intel Macs, 
{cmd:jl} seems to require at least macOS 11 (Big Sur) or 12 (Monterey). On computers not officially supported by those editions, one can use 
the {browse "https://dortania.github.io/OpenCore-Legacy-Patcher/":OpenCore Legacy Patcher} to upgrade anyway--at your own risk.

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
Many Julia programs exploit multithreading. However, Julia is typically installed to only allow 1 thread by default. To 
change this default for {cmd:jl}, edit your operating system's JULIA_NUM_THREADS environment variable. Set it to an integer such as 4 or 8,
or to "auto" to let Julia decide. On CPUs with hyperthreading or efficiency (E) cores as well as performance (P) cores,
the optimal number is usually not the maximum the CPU technically supports. A good guess at the optimum is the number of P cores.

{pstd}
How to set this variable depends on the operating system:

{p 4 6 0}
* In Linux, add "export JULIA_NUM_THREADS=auto" (as an example) to the text file "~/.bashrc". Restart the terminal window.

{p 4 6 0}
* Similarly, in macOS, add such a line to "~/.zshenv".

{p 4 6 0}
* In Windows, use the Environment Variables control panel to add JULIA_NUM_THREADS. One route to that dialog box is to press the Windows logo
button on the keyboard and type "environment variables".

{pstd}
To determine how many threads are available to a {cmd:jl} session, type "{stata "jl: Threads.nthreads()"}" at the Stata prompt.


{title:Options}

{pstd}
{cmd:jl,} {opt qui:etly}{cmd::...} is nearly the same as {cmd:quietly jl:...}. The difference
is that the first will stop the software from copying the output of a Julia command to Stata before suppressing
that output. This will save time if the ou

{pstd}
The {opt inter:ruptible} option of the {cmd:jl:} prefix command makes it possible, at a small performance cost, to interrupt a Julia command the way you
interrupt Stata commands, such as with Ctrl-Break (Windows), Command+. (Mac), or the red X icon in the Stata toolbar. Just as 
with regular Stata commands, the response to an interruption will not always be immediate. For example, a large matrix multiplication
or inversion operation can delay the response.

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
variables will be created with type double or, if {opt replace} is specified, overwritten, subject to any
{ifin} restriction.


{title:Stored results}

{pstd}
{cmd:jl:}, without the {opt qui:etly} option, stores the output in the macro {cmd:r(ans)}.


{title:Stata interface functions}

{pstd}
The {cmd:julia.ado} package includes, and automatically loads, a Julia module that gives access to the 
{browse "https://www.stata.com/plugins":Stata Plugin Interface}, which see for more information on 
syntax. The functions in module allow one to read and write
Stata objects from Julia. The major departure in syntax in these Julia versions is that the functions
that return data, such as an element of a Stata matrix, do so through the return value rather than a
supplied pointer to a pre-allocated storage location. For example, {cmd:jl: SF_scal_use("X")}
extracts the value of the Stata scalar {cmd:X}.

{synoptset 62 tabbed}{...}
{synopthdr:Function}
{synoptline}
{synopt:{bf:SF_nobs()}}Number of observations in Stata data set{p_end}
{synopt:{bf:SF_nvar()}}Number of variables{p_end}
{synopt:{bf:SF_varindex(s::AbstractString)}}Index of variable named s in data set{p_end}
{synopt:{bf:SF_var_is_string(i::Int)}}Whether variable i is string{p_end}
{synopt:{bf:SF_var_is_strl(i::Int)}}Whether variable i is a strL{p_end}
{synopt:{bf:SF_var_is_binary(i::Int, j::Int)}}Whether observation i of variable j is a binary strL{p_end}
{synopt:{bf:SF_sdatalen(i::Int, j::Int)}}String length of variable i, observation j{p_end}
{synopt:{bf:SF_is_missing()}}Whether a Float64 value is Stata missing{p_end}
{synopt:{bf:SV_missval()}}Stata floating-point value for missing{p_end}
{synopt:{bf:SF_vstore(i::Int, j::Int, val::Real)}}Set observation j of variable i to val (numeric){p_end}
{synopt:{bf:SF_sstore(i::Int, j::Int, s::AbstractString)}}Set observation j of variable i to s (string) {p_end}
{synopt:{bf:SF_vdata(i::Int, j::Int)}}Return observation j of variable i (numeric){p_end}
{synopt:{bf:SF_sdata(i::Int, j::Int)}}Return observation j of variable i (string){p_end}
{synopt:{bf:SF_macro_save(mac::AbstractString, tosave::AbstractString)}}Set macro value{p_end}
{synopt:{bf:SF_macro_use(mac::AbstractString, maxlen::Int)}}First maxlen characters of macro mac{p_end}
{synopt:{bf:SF_scal_save(scal::AbstractString, val::Real)}}Set scalar value{p_end}
{synopt:{bf:SF_scal_use(scal::AbstractString)}}Return scalar scal{p_end}
{synopt:{bf:SF_row(mat::AbstractString)}}Number of rows of matrix mat{p_end}
{synopt:{bf:SF_col(mat::AbstractString)}}Number of columns of matrix mat{p_end}
{synopt:{bf:SF_macro_save(mac::AbstractString, tosave::AbstractString)}}Set global macro{p_end}
{synopt:{bf:SF_mat_store(mat::AbstractString, i::Int, j::Int, val::Real)}}mat[i,j] = val{p_end}
{synopt:{bf:SF_mat_el(mat::AbstractString, i::Int, j::Int)}}Return mat[i,j]{p_end}
{synopt:{bf:SF_display(s::AbstractString)}}Print to Stata results window{p_end}
{synopt:{bf:SF_error(s::AbstractString)}}Print error to Stata results window{p_end}
{synoptline}
{p2colreset}{...}


{title:Author}

{p 4}David Roodman{p_end}
{p 4}david@davidroodman.com{p_end}


{title:Acknowledgements}

{pstd}
This project was inspired by James Fiedler's {browse "https://ideas.repec.org/c/boc/bocode/s457688.html":Python plugin for Stata} (as perhaps
was Stata's support for Python).


