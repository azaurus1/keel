FROM quay.io/fedora/fedora-bootc:43

# Locking root
RUN passwd -l root


RUN bootc container lint --fatal-warnings