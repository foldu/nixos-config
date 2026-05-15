# file for cases where swedish man pushes obvious security fixes to main again
{ ... }:
{
  # fixes https://github.com/0xdeadbeefnetwork/ssh-keysign-pwn/
  # qualys at least says this fixes it
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 2;

  # dirty frag: blacklist shit kernel modules nobody ever used
  boot.blacklistedKernelModules = [
    "esp4"
    "esp6"
    "rxrpc"
  ];
}
