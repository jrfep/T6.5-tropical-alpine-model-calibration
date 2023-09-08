source env/project-env.sh

[ -e $PRIVATESCRATCH ] && module add gdal

mkdir -p $SCRIPTDIR/data
cd $SCRIPTDIR/data

## mountain inventory v2.0
if [ ! -e $SCRIPTDIR/data/GMBA_inventory_valid.gpkg ]
then
  GISPATH=topography/global/GMBA-Mountain-Inventory
  GISURL=https://data.earthenv.org/mountains/standard
  mkdir -p $GISDATA/$GISPATH/
  for ARCH in GMBA_Inventory_v2.0_standard_basic.zip GMBA_Inventory_v2.0_standard.zip
  do 
    wget --continue $GISURL/$ARCH --output-document=$GISDATA/$GISPATH/$ARCH
  done

  # version 1.2: GMBA\ mountain\ inventory_V1.2_entire\ world.zip
  unzip -d $SCRIPTDIR/data/ -u $GISDATA/$GISPATH/GMBA_Inventory_v2.0_standard.zip
  ## make valid, declare input encoding
  ogr2ogr -f "GPKG" $SCRIPTDIR/data/GMBA_inventory_valid.gpkg \
    $SCRIPTDIR/data/ GMBA_Inventory_v2.0_standard \
    -nlt PROMOTE_TO_MULTI -makevalid -nln gmba_inventory 
    #-t_srs "+proj=longlat +datum=WGS84"  --config SHAPE_ENCODING LATIN1
fi