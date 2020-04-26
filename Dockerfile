FROM nvidia/cuda:9.2-devel-ubuntu16.04
RUN apt-mark hold nvidia* cuda*; exit 0 
RUN apt update
RUN apt install libeigen3-dev wget software-properties-common git cmake libgl1-mesa-dev libglew-dev libjasper-dev libpng-dev libgtk2.0-0 -y --fix-missing
###Install Pangolin
RUN echo "192.30.255.112  github.com" >> /etc/hosts &&\
git clone https://github.com/stevenlovegrove/Pangolin.git &&\
cd Pangolin && mkdir build && cd build &&\
cmake .. && make -j12 && make install && cp -r ../include/mpark /usr/local/include

###Install python3.6, pip3.6, and evo
RUN LC_ALL=C.UTF-8  add-apt-repository ppa:deadsnakes/ppa -y && apt update && apt install python3.6 -y &&\
 wget https://bootstrap.pypa.io/get-pip.py && python3.6 get-pip.py 
RUN pip3.6 install -i https://pypi.tuna.tsinghua.edu.cn/simple evo

###Start 
ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901
EXPOSE $VNC_PORT $NO_VNC_PORT

### Envrionment config
ENV HOME=/headless \
    TERM=xterm \
    STARTUPDIR=/dockerstartup \
    INST_SCRIPTS=/headless/install \
    NO_VNC_HOME=/headless/noVNC \
    DEBIAN_FRONTEND=noninteractive \
    VNC_COL_DEPTH=24 \
    VNC_RESOLUTION=1280x1024 \
    VNC_PW=vncpassword \
    VNC_VIEW_ONLY=false
WORKDIR $HOME

### Add all install scripts for further steps
ADD ./src/common/install/ $INST_SCRIPTS/
ADD ./src/ubuntu/install/ $INST_SCRIPTS/
RUN find $INST_SCRIPTS -name '*.sh' -exec chmod a+x {} +

### Install some common tools
RUN $INST_SCRIPTS/tools.sh
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

### Install custom fonts
RUN $INST_SCRIPTS/install_custom_fonts.sh

### Install xvnc-server & noVNC - HTML5 based VNC viewer
RUN $INST_SCRIPTS/tigervnc.sh
RUN $INST_SCRIPTS/no_vnc.sh

### Install firefox and chrome browser
RUN $INST_SCRIPTS/firefox.sh
RUN $INST_SCRIPTS/chrome.sh

### Install xfce UI
RUN $INST_SCRIPTS/xfce_ui.sh
ADD ./src/common/xfce/ $HOME/

### configure startup
RUN $INST_SCRIPTS/libnss_wrapper.sh
ADD ./src/common/scripts $STARTUPDIR
RUN $INST_SCRIPTS/set_user_permission.sh $STARTUPDIR $HOME


ENTRYPOINT ["/dockerstartup/vnc_startup.sh"]


CMD ["--wait"]

