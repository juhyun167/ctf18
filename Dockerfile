FROM ubuntu:18.04

# Locale configuration
ENV LC_CTYPE C.UTF-8

# APT update and upgrade
RUN apt update
RUN apt upgrade -y

# Fundamental packages
RUN apt install gcc make git net-tools curl wget -y
RUN apt install python python-dev python3 python3-dev python3-pip -y
RUN apt install libssl-dev libffi-dev build-essential -y
RUN apt install texinfo libreadline-dev libncurses5-dev -y
RUN apt install software-properties-common -y

# Temporal directory
RUN mkdir /root/temp/
WORKDIR /root/temp/

# pip configuration
RUN wget https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python get-pip.py
RUN python3 -m pip install --upgrade pip

# Build gdb 10.1 from source
RUN apt purge gdb
RUN wget https://ftp.gnu.org/gnu/gdb/gdb-10.1.tar.xz
RUN tar xvf gdb-10.1.tar.xz
WORKDIR /root/temp/gdb-10.1/
RUN mkdir build
WORKDIR /root/temp/gdb-10.1/build
RUN ../configure --prefix=/usr --with-system-readline --with-python=/usr/bin/python3 --enable-tui
RUN make
RUN make install

# Clone dotfiles repository
RUN git clone https://github.com/hack-rabbit/dotfiles /root/temp/dotfiles/

# Neovim configuration
# Install neovim
RUN add-apt-repository ppa:neovim-ppa/unstable -y
RUN apt update
RUN apt install neovim python3-neovim -y

# Install Node.js 12.x
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt install nodejs -y

# Install vim-plug
RUN sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
	   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# Create Neovim configuration directory
RUN mkdir /root/.config/
RUN mkdir /root/.config/nvim/

# Copy init.vim configuration file
RUN cp /root/temp/dotfiles/init.vim /root/.config/nvim/

# Install neovim plugins
RUN nvim --headless +PlugInstall +qall

# Install clangd language server
RUN apt install clangd-9 -y
RUN update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-9 100

# Install C/C++ autocomplete extension
RUN nvim --headless +"CocInstall -sync coc-clangd" +qall
RUN nvim --headless +CocUpdateSync +qall

# Install Python autocomplete extension
RUN nvim --headless +"CocInstall -sync coc-pyright" +qall
RUN nvim --headless +CocUpdateSync +qall

# Install Javascript autocomplete extension
RUN nvim --headless +"CocInstall -sync coc-tsserver" +qall
RUN nvim --headless +CocUpdateSync +qall

# End of Neovim configuration

# tmux configuration
# Install tmux
RUN apt install tmux -y

# Copy tmux.conf configuration file
RUN cp /root/temp/dotfiles/.tmux.conf /root/

# End of tmux configuration

# Zsh configuration
# Install zsh
RUN apt install zsh -y

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Copy .zshrc configuration file
RUN cp /root/temp/dotfiles/.zshrc /root/
RUN sed -i "s/home\/$USER/root/g" /root/.zshrc

# End of Zsh configuration

# Install fzf
RUN git clone --depth 1 https://github.com/junegunn/fzf.git /root/.fzf
RUN /root/.fzf/install

# pwndbg configuration
# Install pwndbg
RUN git clone https://github.com/pwndbg/pwndbg /root/pwndbg/
WORKDIR /root/pwndbg/
RUN sed -i s/sudo[[:space:]]//g /root/pwndbg/setup.sh
RUN /root/pwndbg/setup.sh

# Reinstall gdb with "built from source" version
RUN apt purge gdb -y
WORKDIR /root/temp/gdb-10.1/build/
RUN make install

# End of pwndbg configuration

# pwntools confiruation
# For Python 2.7
RUN python -m pip install pwntools

# For Python 3+
RUN python3 -m pip install pwntools

# End of pwntools configuration

# Install rp-lin-x64
RUN wget "https://github.com/0vercl0k/rp/releases/download/v1/rp-lin-x64" -o /usr/local/bin/rp-lin-x64
RUN chmod +x /usr/local/bin/rp-lin-x64

# Install one_gadget
RUN apt install ruby -y
RUN gem install one_gadget

# Install radare2
RUN git clone https://github.com/radareorg/radare2.git /root/radare2/
RUN /root/radare2/sys/install.sh
RUN python -m pip install r2pipe
RUN python3 -m pip install r2pipe

# Install z3-solver
RUN python -m pip install z3-solver
RUN python3 -m pip install z3-solver

# Install bat and hexyl
WORKDIR /root/temp
RUN wget https://github.com/sharkdp/bat/releases/download/v0.15.4/bat_0.15.4_amd64.deb
RUN dpkg -i /root/temp/bat_0.15.4_amd64.deb
RUN wget https://github.com/sharkdp/hexyl/releases/download/v0.8.0/hexyl_0.8.0_amd64.deb
RUN dpkg -i /root/temp/hexyl_0.8.0_amd64.deb

# Clear contents of temporal directory
RUN rm -rf /root/temp/*

# Return to home directory
WORKDIR /root/
