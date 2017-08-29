result=$(printf "_results_%08d.txt" $1)

if [ -e $result ]; then
  rm $result
fi

for i in "$@"; do
  echo $i >> $result
done

