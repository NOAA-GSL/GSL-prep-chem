SHELL=/bin/sh
TARGET=fires_ncfmake.x

# These four will be overridden by the caller:
FFLAGS=
LDFLAGS=
LIBS=
FC=fc

all: $(TARGET)

clean:
	rm -f $(TARGET) *.o *.mod *.a *~

$(TARGET): fires_ncfmake.f  manipufiles.f  netcdf_writroutines.f  species.f
	$(FC) $(FFLAGS) fires_ncfmake.f -o $(TARGET) $(LDFLAGS) $(LIBS)
