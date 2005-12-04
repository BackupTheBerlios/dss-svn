%{!?kernel: %{expand: %%define kernel %(uname -r)}}
%define kversion %(echo %{kernel} | sed -e s/smp// - )
%define krelver %(echo %{kversion} | tr -s '-' '_')
%if %(echo %{kernel} | grep -c smp)
    %{expand:%%define ksmp -smp}
%endif

Summary: Unionfs is a stackable unification file system.
Name: unionfs
Version: 1.0.10
Copyright: GPL
Release: 1_%{krelver}
Requires: kernel%{?ksmp} = %{kversion}, /sbin/depmod
Group: System Environment/Libraries
Source: ftp://ftp.fsl.cs.sunysb.edu/pub/unionfs/unionfs-%{version}.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-root

%description
Unionfs is a stackable unification file system, which can appear to
merge the contents of several directories (branches), while keeping
their physical content separate.  Unionfs is useful for unified source
tree management, merged contents of split CD-ROM, merged separate
software package directories, data grids, and more.  Unionfs allows
any mix of read-only and read-write branches, as well as insertion and
deletion of branches anywhere in the fan-out.

%prep
%setup

%build
make

%install
mkdir -p $RPM_BUILD_ROOT/lib/modules/%{kernel}/kernel/fs
make install PREFIX=$RPM_BUILD_ROOT MODPREFIX=$RPM_BUILD_ROOT

%clean
make clean

%files
%defattr(-,root,root)
%doc AUTHORS ChangeLog COPYING NEWS README

/sbin/unionctl
/sbin/uniondbg
/man/man4/unionfs.4
/man/man8/unionctl.8
/man/man8/uniondbg.8

%if %(echo %{kernel} | grep -c '^2.6')
/lib/modules/%{kernel}/kernel/fs/unionfs.ko
%else
/lib/modules/%{kernel}/kernel/fs/unionfs.o
%endif

%changelog
