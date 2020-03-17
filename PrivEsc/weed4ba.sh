#!/bin/bash
# weed4ba.sh: Well-Engineered Escalation Discovery for BASH
# File: weed4ba.sh
# Author: Diego Boy



# hack: to reduce result pollition, we cache <set> output before declarations in script (such as vars and 
#       functions) and other script-execution side-effects take place
# note: unless this script is sourced (i.e. ". ./script.sh", no quotes but there's a space between the dots :p),
#       values returned by <set> inside this script will differ from <set> called in the parent shell
readonly _W4B_SET=$(set)



# global vars
declare w4b_aggressive
declare w4b_color_results
declare w4b_file_output
declare w4b_mode="all"
declare w4b_verbose



####################################################################################################
### REGION: _formatting
####################################################################################################

# constants for terminal
readonly _W4B_FONT_BOLD=$'\e[1;37m'
readonly _W4B_FONT_COLOR_RED=$'\e[1;31m'
readonly _W4B_FONT_COLOR_GREEN=$'\e[1;32m'
readonly _W4B_FONT_COLOR_YELLOW=$'\e[1;33m'
readonly _W4B_FONT_COLOR_BLUE=$'\e[1;34m'
readonly _W4B_FONT_COLOR_MAGENTA=$'\e[1;35m'
readonly _W4B_FONT_COLOR_CYAN=$'\e[1;36m'
readonly _W4B_FONT_NORMAL=$'\e[0m'
readonly _W4B_SECTION_VPADDING="\n\n"



# fun:
#   prints vertical padding between elements
function _w4b_print_vpadding {
    printf "${_W4B_SECTION_VPADDING}"
}



# fun:
#   prints formatted error
# args: 
#   $1 = the error text
function w4b_print_error {
    printf "${_W4B_FONT_COLOR_RED}${1}${_W4B_FONT_NORMAL}\n"
}



# fun:
#   prints formatted header
# args: 
#   $1 = the header text
function w4b_print_header {
    local len_arg=${#1}
    local len_header=$((${len_arg} + 12))
    _w4b_print_vpadding
    printf "${_W4B_FONT_BOLD}"
    printf "%0.s#" $(seq 1 ${len_header})
    printf "\n${_W4B_FONT_BOLD}###   ${_W4B_FONT_COLOR_YELLOW}${1}${_W4B_FONT_BOLD}   ###\n${_W4B_FONT_BOLD}"
    printf "%0.s#" $(seq 1 ${len_header})
    printf "${_W4B_FONT_NORMAL}\n"
}



# fun:
#   prints formatted subheader
# args: 
#   $1 = the subheader text
function w4b_print_subheader {
    local len_header=${#1}
    _w4b_print_vpadding
    printf "${_W4B_FONT_COLOR_YELLOW}${1}\n${_W4B_FONT_BOLD}"
    printf "%0.s-" $(seq 1 ${len_header})
    printf "${_W4B_FONT_NORMAL}\n"
}



# fun:
#   prints formatted cmd
# args: 
#   $1 = the cmd text
function w4b_print_cmd {
    printf "\n%b" "${_W4B_FONT_BOLD}[+] #>: ${_W4B_FONT_COLOR_CYAN}${1}${_W4B_FONT_NORMAL}\n"
}



# fun:
#   prints formatted cmd
# args: 
#   $1 = the subcmd text
function w4b_print_subcmd {
    printf "\n%b" "${_W4B_FONT_BOLD}[-] ${1}${_W4B_FONT_NORMAL}\n"
}



####################################################################################################
### REGION: w4b cmds
####################################################################################################

# array of words to highlight in cmd output
declare -a _w4b_arr_highlight_output



# fun:
#   loads the list of hightlighted words for the results
function _w4b_exec_init {
    # PUSH IFS
    _w4b_push_ifs
    
    local highlighted_words="
### MISC ###
passwd
password
secret
### OS ###
# OS / kernel
kali
linux
debian
ubuntu
redhat
# arch
i686
x32
x64
x86_64
amd64
arm64
"

    while read -r line; do
        if [[ ${line} ]] && [[ ${line} != \#* ]]; then
            _w4b_arr_highlight_output+=("${line}") 
        fi
    done < <(printf "${highlighted_words}")
    
    # POP IFS
    _w4b_pop_ifs
}



# fun:
#   executes and prints formatted cmd and its results
# args: 
#   $1 = the cmd to execute
# opts:
#   -q = quiet, don't print output
function w4b_exec {
    local quiet
    local cmd=${1}
    if [[ ${1} = "-q" ]]; then
        cmd=${2}
        quiet=true
    fi

    local cmd_output
    local cmd_status
    if [[ ${cmd} = "set" ]]; then
        cmd_output=${_W4B_SET}
        cmd_status=0
    else
        cmd_output=$(eval ${cmd} 2>&1)
        cmd_status=${?}
    fi
    
    # highlight interesting words in cmd output
    if [[ ${w4b_color_results} ]]; then
        for item in ${_w4b_arr_highlight_output[@]}; do
            cmd_output=${cmd_output//${item}/${_W4B_FONT_COLOR_BLUE}${item}${_W4B_FONT_NORMAL}}
        done
    fi
    
    if [[ "${cmd_output}" ]]; then
        # cmd successful
        if [[ ${cmd_status} = 0 ]]; then
            [[ ! ${quiet} ]] && w4b_print_cmd "${cmd}"
            printf "%s\n" "${cmd_output}"
            [[ ! ${quiet} ]] && _w4b_print_vpadding
        # cmd errored and verbose mode on
        elif [[ ${w4b_verbose} = true ]]; then
            [[ ! ${quiet} ]] && w4b_print_cmd "${cmd}"
            w4b_print_error "${cmd_output}"
            [[ ! ${quiet} ]] && _w4b_print_vpadding
        fi
    fi
}



# fun:
#   cats the file if readable
# args:
#   $1 = file to cat
function w4b_cat {
    if [[ -r ${1} ]]; then
        w4b_exec "cat ${1}"
    fi
}



# fun:
#   finds readable files
# args:
#   $1 = list of names to find
# opts:
#   -r = use regex
function w4b_find {
    # PUSH IFS
    _w4b_push_ifs
    
    local regex_mode
    local files=${1}
    if [[ ${1} = "-r" ]]; then
        files=${2}
        regex_mode=true
    fi
    files=$(echo ${files} | sort)

    local msg="w4b_find"
    [[ ${regex_mode} ]] && msg="${msg} (regex)"
    w4b_print_cmd ${msg}

    while read -r name; do
        if [[ ${name} ]] && [[ ${name} != \#* ]]; then
            local find_type="name"
            if [[ ${regex_mode} ]]; then
                find_type="regex"
            elif [[ ${name:0:1} = "/" ]]; then
                # absolute path, name starts with /
                find_type="wholename"
            elif [[ ${name} = "*/*" ]]; then
                # relative path, name contains /
                name="*/${name}"
            fi

            # if agressive mode, print each find cmd 
            local find_cmd="find / -${find_type} '${name}' 2> >(grep -vi ': Permission denied' >&2) | grep ."
            if [[ ${w4b_aggressive} ]]; then
                local subcmd=$([[ ${regex_mode} ]] && echo "(regex) "; echo ${name})
                w4b_print_subcmd "${subcmd}"
                w4b_exec "${find_cmd} | sort"
            else
                w4b_exec -q "${find_cmd} | sort"
            fi
        fi
    done < <(printf "${files}")
    
    # POP IFS
    _w4b_pop_ifs
}



####################################################################################################
### REGION: _internal_helpers
####################################################################################################

# to cache IFS
declare _w4b_old_ifs



# fun:
#   caches the value of IFS and substitutes it
# args:
#   $1 = new IFS value
function _w4b_push_ifs {
    _w4b_old_ifs=${IFS}
    IFS=${1}
}



# fun:
#   resets IFS to the cached value
function _w4b_pop_ifs {
    IFS=${_w4b_old_ifs}
}



# fun:
#   wrapper for all initializers
function _w4b_init {
    _w4b_exec_init
}



####################################################################################################
### REGION: helpers
####################################################################################################



# fun:
#   displays the banner
# args: 
#   $1 = if set, print color
function w4b_print_banner {
    local format
    if [[ ${1} ]]; then
        format=${_W4B_FONT_COLOR_GREEN}
    fi

    printf "\
${format}######################################################
${format}#                                                    #
${format}#     Well-Engineered         |||•|||      ) ( (     #
${format}#     Escalation             ( ◣   ◢ )     (  )      #
${format}#     Disc0very       ____oOO___(_)___OOo____(       #
${format}#     for Bash       (_______weed4ba.sh______)       #
${format}#                                                    #
${format}######################################################
"

    if [[ ${1} ]]; then
        printf "${_W4B_FONT_NORMAL}"
    fi
}



# fun:
#   displays the help message
# args: 
#   $1 = if set, print color
function w4b_print_help {
    w4b_print_banner ${*}
    printf "\n"
    printf "Usage: $(basename ${0}) [options]\n"
    printf "\n"
    printf "Options:\n"
    printf "      -a                Aggressive mode - heavy use of regex, extensive enum (slower)\n"
    printf "      -f                Output to files instead of STDOUT\n"
    printf "      -i                Highlight interesting regex in cmd results (slow)\n"
    printf "      -l                List enumeration modes\n"
    printf "      -m                Enumeration modes (csv, default: ALL)\n"
    printf "      -v                Verbose mode (show STDERR)\n"
    printf "      -h                Display this help message\n"
}



# fun:
#   parses the args and validates them
function w4b_parse_args {
    while getopts ':afilm:vh' OPTION; do
        case "${OPTION}" in
            a) w4b_aggressive=true;;
            f) w4b_file_output=true;;
            i) w4b_color_results=true;;
            l) w4b_print_banner; w4b_print_modes; return 1;;
            m) w4b_mode="${OPTARG}";;
            v) w4b_verbose=true;;
            h) w4b_print_help; return 1;;
            :) printf "Error: -${OPTARG} requires an argument.\n";&
            *) printf "\n"; w4b_print_help; return 2;;
            
        esac
    done
    #shift "$((${OPTIND} -1))"
}



# fun:
#   writes to .w4b file or STDOUT depending on init args
# args:
#   $1 = filename
function w4b_write_output {
    local file="${1}.w4b"
    rm -f "${file}"
    while read -r line; do
        if [[ ${w4b_file_output} ]]; then
            printf "%s\n" "${line}" >> "${file}"
        else
            printf "%s\n" "${line}"
        fi
    done
}



####################################################################################################
### REGION: main
####################################################################################################

# fun:
#   enumerates Operating System
function w4b_enum_OS {
    w4b_print_header "Operating System"

    # Distribution
    w4b_print_subheader "Distribution"
    w4b_cat "/etc/issue" # prelogin message and identification file
    w4b_cat "/etc/*release" # distro release file

    # Kernel
    w4b_print_subheader "Kernel"
    w4b_exec "uname -a" # get all system info (kernel, distro, arch and hostname)
    w4b_exec "rpm -q kernel" # query installed kernel (distro:RedHat)
    w4b_exec "dmesg | grep Linux" # look for string in kernel messages
    w4b_exec "ls /boot | grep vmlinuz-" # look for kernel executable binary
    w4b_cat "/proc/version" # kernel version and gcc version used for compilation
    w4b_exec "file /bin/ls" # look for arch
}



# fun:
#   enumerates Networking
function w4b_enum_Networking {
    w4b_print_header "Networking"

    w4b_print_subheader "Host"
    w4b_exec "hostname" # get hostname
    w4b_exec "dnsdomainname" # get DNS domain name

    w4b_print_subheader "Interfaces & Caches"
    w4b_exec "/sbin/ifconfig -a" # list all network interfaces
    w4b_exec "arp -en | tee >(head -n 1) | tail -n +2 | sort" # pritified version of ARP communications
    w4b_exec "arp -a" # display ARP communications
    
    w4b_print_subheader "Sockets"
    w4b_exec "lsof -i" # show all internet connections
    w4b_exec "netstat -antp" # list all TCP sockets and related PIDs
    w4b_exec "netstat -anup" # list all UDP sockets and related PIDs
    w4b_exec "netstat -anxp" # list all UNIX sockets and related PIDs
    w4b_exec "netstat -lnutp" # list all listening sockets and related PIDs
    
    w4b_print_subheader "Routing"
    w4b_exec "iptables -L" # list all rules
    w4b_exec "route" # display route information
    w4b_exec "/sbin/route -nee" # route info, verbose++

    w4b_print_subheader "Interesting Files"
    w4b_find "
/etc/networks
/etc/network/interfaces
/etc/resolv.conf
/etc/sysconfig/network
"
}



# fun:
#   enumerates Devices & Filesystems
function w4b_enum_DevicesAndFilesystems {
    w4b_print_header "Devices & Filesystems"

    # CPU
    w4b_print_subheader "CPU"
    w4b_cat "/proc/cpuinfo"

    # Printers
    w4b_print_subheader "Printers"
    w4b_exec "lpstat -a" # get all printers (CUPS)

    # Filesystem
    w4b_print_subheader "Filesystem"
    w4b_exec "df -h" # get space avialable on mounted filesystems in human readable format
    w4b_exec "df -a" # get space available on all (dummy/unmounted included) filesystems

    # Mounts
    w4b_print_subheader "Mounts"
    w4b_exec "mount" # list all mounted filesystems
    w4b_cat "/etc/fstab" # contains mounted and unmounted filesystems
}



# fun:
#   enumerates Environment Variables
function w4b_enum_EnvVars {
    w4b_print_header "Environment Variables"

    w4b_exec "env" # env vars
    w4b_exec "set" # shell vars
    w4b_exec "pwd" # present working dir
    w4b_exec "echo \${HOME}" # is HOME (~) the expected dir?
    w4b_exec "echo \${PATH}" # check for PATH interception (i.e. PATH=.;$PATH)
    w4b_find "
/etc/bashrc
/etc/profile
/home/*/.bash_profile
/home/*/.bashrc
/home/*/.bash_logout
/home/*/.profile
/root/.bash_profile
/root/.bashrc
/root/.bash_logout
/root/.profile
/etc/shells
"
}



# fun:
#   enumerates Users & Groups
function w4b_enum_UsersAndGroups {
    w4b_print_header "Users & Groups"

    # all users/groups
    w4b_print_subheader "Current"
    w4b_exec "whoami" # username for current user
    w4b_exec "id" # real and effective user/group IDs (ruid & euid) for current user

    
    # all users/groups
    w4b_print_subheader "All"
    w4b_exec "for i in $(w4b_cat /etc/passwd | cut -d":" -f1); do id \$i;done " # all uid’s and respective group memberships
    w4b_exec "grep -v -E '^#' /etc/passwd | awk -F: '\$3 == 0 { print \$1}'" # all superuser accounts
    
    # users currently logged in
    w4b_print_subheader "Logged-in"
    w4b_exec "finger"
    w4b_exec "pinky"
    w4b_exec "users"
    w4b_exec "who -a"
    w4b_exec "w" # users + their processes

    # users not logged in
    w4b_print_subheader "Not logged-in"
    w4b_exec "last" # users recently logged in/out
    w4b_exec "lastlog" # last time all users logged in

    w4b_print_subheader "Interesting Files"
    w4b_find "
/etc/passwd*
/etc/shadow*
/etc/group*
/etc/sodoers*
/home/*
/root
/var/log/auth.log*
/var/mail/*
/var/spool/mail/*
"  
}



# fun:
#   enumerates Processes & Jobs
function w4b_enum_ProcessAndJobs {
    w4b_print_header "Processes & Jobs"

    # processes run by root
    w4b_print_subheader "Processes (root)"
    w4b_exec "ps aux | grep root"
    w4b_exec "ps -ef | grep root"

    # all processes
    w4b_print_subheader "Processes (all)"
    w4b_exec "ps aux"
    w4b_exec "ps -ef"
    w4b_exec "top -b -n 1"
    w4b_exec "ps aux | awk '{print \$11}'|xargs -r ls -la |awk '!x[\$0]++'" # lookup process binary path and permissions

    # cron jobs
    w4b_print_subheader "CRON Jobs"
    w4b_exec "crontab -l" # list cron jobs for current user
    w4b_find "
/etc/at.allow
/etc/at.deny
/etc/*cron*
/var/spool/cron/*
"

}



# fun:
#   enumerates Apps & Services
function w4b_enum_AppAndSvc {
    w4b_print_header "Apps & Services"
    
    # installed
    #w4b_print_subheader "Installed"
    #w4b_exec "dpkg -l" # list installed packages (distro:Debian,Ubuntu)
    #w4b_exec "rpm -qa" # list installed packages (distro:RedHat)
    #w4b_exec "pkg_info" # list installed packages (distro:OpenBSD,FreeBSD)
    #w4b_exec "chkconfig --list" # list all system services (distro:RedHat)
    #w4b_find "
#/var/cache/apt/archiveso
#/var/cache/yum
#/usr/bin/*
#/sbin/*
#"
    
    # history
    w4b_print_subheader "History"
    w4b_exec "history" # command history for current shell
    w4b_find "
/home/*/.*_history
/root/.*_history
"

    # sudo, setuid & setgid
    w4b_print_subheader "Run As"
    w4b_exec "sudo -nV" # sudo version, does an exploit exist?
    w4b_exec "sudo -nl" # list user's privs non-interactively
    w4b_exec "sudo -nl | grep -w 'awk\|bash\|chmod\|cp\|find\|irb\|less\|lua\|man\|more\|nc\|netcat\|nmap\|perl\|python\|ruby\|sh\|vi\|vim\|zsh'" # any binaries we can sudo and get shell from?
    w4b_exec "find / -xdev -type f -perm /4000 -exec ls -dl {} \\; 2>/dev/null || true" # find setuid files
    w4b_exec "find / -xdev -type f -perm /2000 -exec ls -dl {} \\; 2>/dev/null || true" # find setgid files

    w4b_find "/etc/sudoers"
}



# fun:
#   print enumeration modes
function w4b_print_modes {
printf "
Enumeration modes (default = ALL):
   1. os                OS
   2. net               Networking
   3. dev_fs            Devices & Filesystems
   4. env               Environment Variables
   5. users_groups      Users & Groups
   6. procs_jobs        Processes & Jobs
   7. app_svc           Apps & Services
"
}



# fun:
#   main
# args:
#   $* = args for weed4ba.sh (see fun w4b_print_help for usage)
function w4b {
    # if parse args succeeds then init, else return parse error code
    w4b_parse_args ${*} 
    [[ ${?} -ne 0 ]] && return ${?} || _w4b_init
    
    # only print banner when using STDOUT output
    #if [[ ! ${w4b_file_output} ]]; then
        w4b_print_banner true
    #fi
    
    for mode in $(echo ${w4b_mode} | tr ',' '\n'); do
        case "${mode,,}" in
            "os" | "all") w4b_enum_OS | w4b_write_output "os";&
            "net" | "all") w4b_enum_Networking | w4b_write_output "net";&
            "dev_fs" | "all") w4b_enum_DevicesAndFilesystems | w4b_write_output "dev_fs";&
            "env" | "all") w4b_enum_EnvVars | w4b_write_output "env";&
            "users_groups" | "all") w4b_enum_UsersAndGroups | w4b_write_output "users_groups";&
            "procs_jobs" | "all") w4b_enum_ProcessAndJobs | w4b_write_output "procs_jobs";&
            "app_svc" | "all") w4b_enum_AppAndSvc | w4b_write_output "app_svc";;
            *) w4b_print_error "Invalid mode: ${mode}"
        esac
    done
}



# call main function only if script is called directly, i.e. not sourced
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && w4b ${*} || true