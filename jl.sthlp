{smcl}
{* *! jl 0.5.1 19 November 2023}{...}
{help jl:jl}
{hline}{...}

{title:Title}

{pstd}
Bridge to Julia{p_end}

{title:Syntax}

{phang}
{cmd:jl} [, {cmdab:qui:etly}]: {it:juliaexpr}

{phang2}
where {it:juliaexpr} is an expression to be evaluated in Julia.

{phang}
{cmd:jl} {it:subcommand} [{varlist}], [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt PutVarsToDF}}Copy Stata variables to Julia DataFrame, handling missings{p_end}
{synopt:{opt PutVarsToDFNoMissing}}Copy Stata variables to Julia DataFrame; no handling of missings{p_end}
{synopt:{opt PutVarsToMat}}Copy Stata variables to Julia matrix, handling missings{p_end}
{synopt:{opt PutVarsToDFNoMissing}}Copy Stata variables to Julia matrix; no handling of missings{p_end}
{synopt:{opt GetVarsFromDF}}Copy Stata variables from Julia DataFrame, mapping NaN to missing{p_end}
{synopt:{opt GetVarsFromMat}}Copy Stata variables from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt PutMatToMat}}Copy Stata matrix to Julia matrix, mapping missing to NaN{p_end}
{synopt:{opt GetMatFromMat}}Copy Stata matrix from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt AddPkg}}Install Julia packages if not already installed{p_end}
{synopt:{opt UpPkg}}Update Julia packages{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{cmd:jl PutVarsToDF} [{varlist}] {ifin}, [{opt dest:ination(string)} {opt col:s(string)}]

{phang}
{cmd:jl PutVarsToDFNoMissing} [{varlist}] {ifin}, [{opt col:s(string)} {opt dest:ination(string)}]

{phang}
{cmd:jl PutVarsToMat} [{varlist}] {ifin}, [{opt dest:ination(string)}]

{phang}
{cmd:jl PutVarsToMatNoMissing} [{varlist}] {ifin}, [{opt dest:ination(string)}]

{phang}
{cmd:jl GetVarsFromDF} {varlist} {ifin}, [{opt cols(string)} {opt source({varlist})} {opt replace}]

{phang}
{cmd:jl GetVarsFromMat} {varlist} {ifin}, [{opt source(string)}]

{phang}
{cmd:jl PutMatToMat} {it:matname}, [{opt dest:ination(string)}]

{phang}
{cmd:jl GetMatFromMat} {it:matname}, [{opt source(string)}]

{phang}
{cmd:jl AddPkg} {it:namelist}

{phang}
{cmd:jl UpPkg} {it:namelist}


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
Because Julia does just-in-time-compilation, sometimes commands take longer on first use.

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
The data-copying subcommands are low-level and high-performance. On the Stata side, they interact with
the {browse "https://www.stata.com/plugins":Stata Plugin Interface} (SPI). When copying 
from Stata to Julia, all numeric data, whether stored as {cmd:byte}, {cmd:int}, 
{cmd:long}, {cmd:float}, or {cmd:double}, is converted
to {cmd:double}--{cmd:Float64} in Julia--beacuse that is how the SPI provides the values. 

{pstd}
The subcommands whose names end with "NoMissing" are intended for data known to contain
no missing values; they are faster. How they map missing values is indeterminate. In
contrast, {cmd:PutVarsToDF} maps Stata missing values to Julia {cmd:missing}.
As a result, columns in the destination DataFrame will have type {cmd:Vector{Float64?}}, which is short for
Vector{Union{Missing, Float64}}, and is the standard type for accomodating missing values.


{marker installation}{...}
{title:Installing Julia}

{pstd}
This package is designed to work in 64-bit Windows, Linux, and MacOSX (with an Intel or Apple CPU). For it to function, 
Julia must be installed and the Julia /bin directory must be present in the system search path. The easiest way to assure that state
of affairs depends on your operating system:

{p 4 6 0}
* In {bf:Linux}, install Julia {browse "https://github.com/JuliaLang/juliaup#mac-and-linux":via the installation manager juliaup}. As documented
at that link, installation requires a single command.

{p 4 6 0}
* Unfortunately, if you install via juliaup in Windows or macOS, Stata will not be able to find Julia. Instead, download and install
the {browse "https://julialang.org/downloads":current stable release} of Julia and follow the
{browse "https://julialang.org/downloads/platform/":platform-specific instructions}--ignoring any 
advice to use juliaup--in order to assure that the needed Julia directory is in the system path. In {bf:Windows}, that just requires checking "Add Julia to PATH"
in a dialog box during installation.

{p 4 6 0}
* In {bf:macOS}, after installation, you need to {browse "https://support.apple.com/guide/terminal/open-or-quit-terminal-apd5265185d-f365-44cb-8b09-71a064a42125":open a Terminal}
and execute the three command lines under "macOS" in the {browse "https://julialang.org/downloads/platform/":platform-specific instructions}. On Intel Macs, 
{cmd:jl} seems to require at least macOS 11 (Big Sur) or 12 (Monterey) to run reliably. On computers not officially supported by those editions, one can use 
the {browse "https://dortania.github.io/OpenCore-Legacy-Patcher/":OpenCore Legacy Patcher} to upgrade anyway--at your own risk.

{pstd} If the Julia package DataFrames.jl is not installed, {cmd:jl} will attempt to install it on first
use. {it:That requires an Internet connection and can take several minutes.}


{title:Options}

{pstd}
{cmd:jl,} {opt qui:etly}{cmd::...} is nearly the same as {cmd:quietly jl:...}. The difference
is that the first will stop the software from copying the output of a Julia command to Stata before suppressing
that output. This will save time if the output is, say, the contents of a million-element vector.

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


