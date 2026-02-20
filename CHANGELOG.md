# Changelog
## [v0.2.1](https://github.com/szaghi/FLAP/tree/v0.2.1) (2026-02-20)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.2.0...v0.2.1)
### Documentation
- Add VitePress site and overhaul project infrastructure ([`e36ecf4`](https://github.com/szaghi/FLAP/commit/e36ecf4d5c5abe51a9c9295c7019bd568d6b4774))

## [v0.2.0](https://github.com/szaghi/FLAP/tree/v0.2.0) (2025-06-25)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.1.0...v0.2.0)
### Bug fixes
- Fix parse support of nested and repeated tags ([`5688b6e`](https://github.com/szaghi/FLAP/commit/5688b6e79752ee1700dfd72b4a7c3b2bbe224ee7))

### Miscellaneous
- Merge tag 'v0.1.0' into develop

Fix parsing bug issue[#7](https://github.com/szaghi/FLAP/issues/7) ([`0043425`](https://github.com/szaghi/FLAP/commit/0043425bee7a9c07936d8b0ceb64b18418d9f6be))
- Update submodules ([`43d5dcb`](https://github.com/szaghi/FLAP/commit/43d5dcb9e1228dbb7aab409d8a490f097114e666))
- Merge branch 'master' into develop ([`f78533d`](https://github.com/szaghi/FLAP/commit/f78533d2b4ca546f920c18adc861bf276d91893d))
- Update submodules ([`c398faa`](https://github.com/szaghi/FLAP/commit/c398faacd3339568d39df42f3d4d2f02a6958600))
- Update submodule ([`0416ed6`](https://github.com/szaghi/FLAP/commit/0416ed6856ceff89a2b673e59a37541d05fb1b95))
- Merge branch 'master' into develop ([`1b8867c`](https://github.com/szaghi/FLAP/commit/1b8867cf049ee7efa1499eb97c115dd9ecdbecf3))
- Re-add pre-processing flag for unsupported R16P ([`fc224d2`](https://github.com/szaghi/FLAP/commit/fc224d216cc87f3ac0ac2e4d9e6f0ff1a479f956))
- Add fpm support ([`06f8ff5`](https://github.com/szaghi/FLAP/commit/06f8ff513c6ff86898f825981d166f406397e958))
- Merge pull request [#9](https://github.com/szaghi/FLAP/issues/9) from zoziha/add-fpm-support

Add fpm support ([`1379f0b`](https://github.com/szaghi/FLAP/commit/1379f0bbc82758f0f0066a7af7de094357cf9d00))
- Add CMake support ([`cf67bed`](https://github.com/szaghi/FLAP/commit/cf67bedac126e59a750acdccf80fc77116f749f1))
- Update third party libraries ([`c465680`](https://github.com/szaghi/FLAP/commit/c4656807daa7b317ebdddb37556957fc0c7a0f3b))
- Merge pull request [#10](https://github.com/szaghi/FLAP/issues/10) from MarcoGrossi92/cmake_branch

CMake + submodules update ([`f7a5a36`](https://github.com/szaghi/FLAP/commit/f7a5a363e4cccca1ce383684c7bfa051768f9af0))
- Fix a bug in the file src/lib/CMakeLists.txt

At line 11, foxy_xml_tag.f90 is changed to foxy_xml_tag.F90. ([`45a44bc`](https://github.com/szaghi/FLAP/commit/45a44bc6f071dc832a26f206eca7fe3b0aa533bd))
- Merge pull request [#11](https://github.com/szaghi/FLAP/issues/11) from FlorianECN/Fix_cmake_Bug

Fix a bug in the file src/lib/CMakeLists.txt ([`294b040`](https://github.com/szaghi/FLAP/commit/294b040e62f14ebec78429a13796631af7a1356e))
- Update StringiFor version ([`8b6b093`](https://github.com/szaghi/FLAP/commit/8b6b093b16f9afb5d8493759ae5ac435e3cb2f6f))
- Merge pull request [#12](https://github.com/szaghi/FLAP/issues/12) from Xavier-Maruff/stringifor-version

Update StringiFor commit hash in fpm.toml ([`7a58b58`](https://github.com/szaghi/FLAP/commit/7a58b5827ae02c73c7ab8376220b8e1b45c7dc14))
- Update submodules ([`472e2db`](https://github.com/szaghi/FLAP/commit/472e2db787b0ee40eeb5fd6a6e5011d0a10084bf))
- Developing new tag tokenizer supporting nested tags with the same name of parents ([`815baa4`](https://github.com/szaghi/FLAP/commit/815baa46c64146cc759c4e37b5b141277ce360fa))
- Improve XML input parsing ([`fa0437e`](https://github.com/szaghi/FLAP/commit/fa0437e24dfc98d666864d4c49987540b89cecb6))

## [v0.1.0](https://github.com/szaghi/FLAP/tree/v0.1.0) (2019-09-19)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.8...v0.1.0)
### Bug fixes
- Fix submodule links ([`8635be5`](https://github.com/szaghi/FLAP/commit/8635be5f783c851e540cb806203e62c79c947a97))

### Miscellaneous
- Merge tag 'v0.0.8' into develop

Fix bug on elemental attribute abuse, stable release, fully backward compatible. ([`c270f21`](https://github.com/szaghi/FLAP/commit/c270f21cc723e446d6d7400b970eab8e0fdbf906))
- Update submodules ([`66b0aab`](https://github.com/szaghi/FLAP/commit/66b0aabd9662203a821debbda9a17b8c6c3b95ec))
- Suggested fix for compile error using Intel-2017.1.143 on Windows

The Intel Fortran compiler 2017.1.143 on windows does not accept line
328 and 347 in foxy_xml_tag.f90. I thing the compiler is correct on this
issue. By definition function results behave like dummy arguments with
intent(out). They are undefined when the function initiate. Hence they
can not first appear on the right hand side of assignments. (Reference
is made to page 78 of "Modern Fortran Explained" by Metcalf, Reid and
Cohen) If the intention with these functions is to update whatever
object is associated with _tag the functions must be turned into
subroutines where _tag has intent(inout). ([`433b48c`](https://github.com/szaghi/FLAP/commit/433b48c0224a8816100fe748a7be927167addd00))
- Merge pull request [#5](https://github.com/szaghi/FLAP/issues/5) from jeblohe/master

Suggested fix for compile error using Intel-2017.1.143 on Windows ([`9cea38e`](https://github.com/szaghi/FLAP/commit/9cea38e5be69908c8b2c38dfdfb47f1cfcfd9445))
- Merge branch 'master' of github.com:Fortran-FOSS-Programmers/FoXy ([`e57c14a`](https://github.com/szaghi/FLAP/commit/e57c14a16153a8c6cfd401dd32f34fcb2afc988e))
- Update submodules ([`765d9b3`](https://github.com/szaghi/FLAP/commit/765d9b3266cdf7e84ae5632070722d5d5f1116f1))
- Add missing submodule

Add missing submodule: BeFoR64 library was missing. ([`ef2d239`](https://github.com/szaghi/FLAP/commit/ef2d2399a7f659591b95d50e1bdc031a28f27cd4))
- Update submodules ([`bd10120`](https://github.com/szaghi/FLAP/commit/bd10120f411b6c290880da63ab802b6de2d86485))
- Update stringifor submodule ([`2b39556`](https://github.com/szaghi/FLAP/commit/2b39556220a765925ee61b9e9465f77f6beb86f2))
- Merge branch 'master' into develop ([`dd69376`](https://github.com/szaghi/FLAP/commit/dd6937602cd35e3cd3937e3f3d73fea7d3ff9200))
- Clean and Fix GCC9 regression

Clean the code style and fix a regression with GCC9: it seems that GCC9
generates and ICE if the object xml_tag has a defined filazer. Now there
is a preprocessing flag that check the version of GCC and if it is newer
than 8.x trunk the finalizer is trimmed out. ([`9b30875`](https://github.com/szaghi/FLAP/commit/9b3087500c1b5937890279faa1456f421766b86e))
- Fix parsing bug issue[#7](https://github.com/szaghi/FLAP/issues/7)

The methods `content` and `search` were bugged, fixed the algorithm. ([`fdcb58e`](https://github.com/szaghi/FLAP/commit/fdcb58e9fc441c321e2d56463b98cf9f09498dd5))
- Update travis config ([`3009e3f`](https://github.com/szaghi/FLAP/commit/3009e3fb97c4c22d85128fdae5c3849f105d9b08))
- Merge branch 'release/0.1.0' ([`0e2b7ad`](https://github.com/szaghi/FLAP/commit/0e2b7ada09715a2f1b1a1c680294eb57ec1a7747))

## [v0.0.8](https://github.com/szaghi/FLAP/tree/v0.0.8) (2016-07-11)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.7...v0.0.8)
### Miscellaneous
- Merge tag 'v0.0.7' into develop

Minor improvements, stable release, fully backward compatible. ([`806a41d`](https://github.com/szaghi/FLAP/commit/806a41d8385655e983c5d567c13d4245a3c1c342))
- Improve stringify and write methods ([`cff4b81`](https://github.com/szaghi/FLAP/commit/cff4b8198dc4dc621661ca7ac2992e781350b1cf))
- Merge branch 'master' into develop ([`aeefd87`](https://github.com/szaghi/FLAP/commit/aeefd87da5da98b4a3e6d7551637a0cbbeca9319))
- Fix non standard abuse of elmental attribute

Fix non standard abuse of elmental attribute on some new xml_tag
methods. ([`9b317b7`](https://github.com/szaghi/FLAP/commit/9b317b7527e8d7057a1fd40df9473d78bee69c8e))
- Merge branch 'hotfix/0.0.8' ([`59c0524`](https://github.com/szaghi/FLAP/commit/59c052421bdb11edf0aefe92ec458b0adb63a6a5))

## [v0.0.7](https://github.com/szaghi/FLAP/tree/v0.0.7) (2016-07-04)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.6...v0.0.7)
### Bug fixes
- Fix impure setters ([`0153e92`](https://github.com/szaghi/FLAP/commit/0153e928238d5e4f9aa162c0864ef050ca07716b))
- Fix self_closing_tag method bug ([`9601d39`](https://github.com/szaghi/FLAP/commit/9601d39dc198ef8302a77c4dd4e3202ca3916ef1))

### Miscellaneous
- Merge tag 'v0.0.6' into develop

Improve setters, stable release, fully backward compatible. ([`1c548cb`](https://github.com/szaghi/FLAP/commit/1c548cbfbb60b18f8c76f890912ec839ffd6500e))
- Improve indendation handling ([`b34a1a5`](https://github.com/szaghi/FLAP/commit/b34a1a50aae742e209521bae1975b0ec27120157))
- Improve attributes handling ([`92df04b`](https://github.com/szaghi/FLAP/commit/92df04b34e6ed4a0231c1f889b7afc742edb87b6))
- Try to fix issue on null stream of attributes ([`f06dab1`](https://github.com/szaghi/FLAP/commit/f06dab1f00fc0ba0185a3a2b3f594a1869f150a6))
- Make more flexible end_tag method ([`84ef749`](https://github.com/szaghi/FLAP/commit/84ef7490820508c8a8ede86a187ca7e23370c392))
- Merge branch 'master' into develop ([`08b9e30`](https://github.com/szaghi/FLAP/commit/08b9e30389d340832af695379c4e44abd1a9774a))
- Add write_tag method to xml_tag class ([`2f45f37`](https://github.com/szaghi/FLAP/commit/2f45f37a35ece83b3491faca00e1ca395963f19a))
- Merge branch 'release/0.0.7' ([`7066672`](https://github.com/szaghi/FLAP/commit/7066672e1bd193bc4345cf3558840a53ff0c9359))

## [v0.0.6](https://github.com/szaghi/FLAP/tree/v0.0.6) (2016-07-04)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.5...v0.0.6)
### Bug fixes
- Fix readme typos ([`d168b36`](https://github.com/szaghi/FLAP/commit/d168b36d77662ff5f10157692dac563ce35501a1))

### Miscellaneous
- Merge tag 'v0.0.5' into develop

Add emitter facility, stable release, not fully backward compatible. ([`f4eebae`](https://github.com/szaghi/FLAP/commit/f4eebae521198153c9d1daa605fafd36e5961a35))
- Add tag methods from OOP-refactoring branch of Lib_VTK_IO ([`164371d`](https://github.com/szaghi/FLAP/commit/164371da37f09460759c4881b766bee93b9509ce))
- Merge branch 'master' into develop ([`d001923`](https://github.com/szaghi/FLAP/commit/d00192374444ea86c0508f0405d286d790181bde))
- Update submodules ([`4232eeb`](https://github.com/szaghi/FLAP/commit/4232eeb0a528f0f323fb7c8e3afad0690de0c942))
- Update submodules ([`13b99b3`](https://github.com/szaghi/FLAP/commit/13b99b3a7b3517b30f7954a26f4323cd45728c39))
- Improve setters ([`6842f4a`](https://github.com/szaghi/FLAP/commit/6842f4aef2ce81e241b2035d2f944af9370c3025))
- Merge branch 'release/0.0.6' ([`e56b884`](https://github.com/szaghi/FLAP/commit/e56b884e4d026b4fa71081cd82ea7f6efd8235a0))

## [v0.0.5](https://github.com/szaghi/FLAP/tree/v0.0.5) (2016-06-28)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.3...v0.0.5)
### Bug fixes
- Fix doc deploy issue into travis config ([`994237c`](https://github.com/szaghi/FLAP/commit/994237cc91db2d210f28cd57780cfb939152fd0b))
- Fix bad merging... ([`6a05d60`](https://github.com/szaghi/FLAP/commit/6a05d600612900975a0d01cef82ebfbce33b52b1))
- Fix readme ([`f430007`](https://github.com/szaghi/FLAP/commit/f430007f9263898ae30370a31799ec99e622cb60))

### Miscellaneous
- Merge tag 'v0.0.3' into develop

Stable release, fully backward compatible. ([`cf914b1`](https://github.com/szaghi/FLAP/commit/cf914b16f29403f33334f6fe0efb556e3101813b))
- Update submodules config to point to master branch ([`972855b`](https://github.com/szaghi/FLAP/commit/972855b337f3ed107271540f9d9b4455abe6b7fb))
- Add tag function to create a tag ([`dc644c4`](https://github.com/szaghi/FLAP/commit/dc644c437c5a6d1ba0a0d6476b4c15993b6dddeb))
- Expose xml tag class

Expose xml tag class: necessary to create emitter facility. ([`4936878`](https://github.com/szaghi/FLAP/commit/493687822770265dc1fe90d76c4e2a2ceae657a4))
- Expose xml file add tag method

Expose xml file add tag method: necessary to create emitter facility. ([`16af0ef`](https://github.com/szaghi/FLAP/commit/16af0ef59885e051fc9467da3e7533962a938fde))
- Add xml tag set method skeleton

Add xml tag set method skeleton: to be completed. ([`0cdaf32`](https://github.com/szaghi/FLAP/commit/0cdaf3277b66d91cac07a653a671a0bede1daadf))
- Fix xml tag set method bug

Fix xml tag set method bug: cannot be elemental, at best it is pure. ([`71f8719`](https://github.com/szaghi/FLAP/commit/71f8719c413423e5cf4063b5befe6628f9c8d160))
- Merged from remote ([`61df6a2`](https://github.com/szaghi/FLAP/commit/61df6a259e30b1da7cfee4300088b0a84b0e3435))
- Improve set methods ([`87acb27`](https://github.com/szaghi/FLAP/commit/87acb271c0f209923f57abc891729576740bfff2))
- Merge branch 'master' into develop ([`be7fcc8`](https://github.com/szaghi/FLAP/commit/be7fcc84eee95ff229e30ab460661dc67628689b))
- Add self-closing tag facility ([`f1d5439`](https://github.com/szaghi/FLAP/commit/f1d54394ee0d7b3b9a9155056f30752a0579e61a))
- Implement delete facilities

Implement delete facilities: nested tags delete still missing, will be
probably implemented when DOM facility will be completed. ([`64d3331`](https://github.com/szaghi/FLAP/commit/64d3331c5b04d62383818eff5abee4034def19e1))
- Merge branch 'release/0.0.5' ([`d3c3858`](https://github.com/szaghi/FLAP/commit/d3c38584182194daa08c5e3037a4d636435007a0))

## [v0.0.3](https://github.com/szaghi/FLAP/tree/v0.0.3) (2016-06-09)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.2...v0.0.3)
### Miscellaneous
- Merge tag 'v0.0.2' into develop

Switch to PENF and StringiFor, stable release, not fully backward compatible. ([`c893ccf`](https://github.com/szaghi/FLAP/commit/c893ccfbc01a43b3c23cb26adad1d33c3a29d14a))
- Update readme ([`3f498e5`](https://github.com/szaghi/FLAP/commit/3f498e5890f8a96852fa9a5221b9b1f1c25cdae1))
- Merge branch 'master' into develop ([`d6c9d61`](https://github.com/szaghi/FLAP/commit/d6c9d6108402b0a168cac87c40e85a9d3361ac0c))
- Add ford documentation support ([`3c94f02`](https://github.com/szaghi/FLAP/commit/3c94f02c5627bc99b78705b48d60bda3aa4c83ec))
- Add parse file capability

Add parse file capability.

Refactor tests suite. ([`441260c`](https://github.com/szaghi/FLAP/commit/441260c9dd01d2488120f35e637a2b2162e2e9e5))
- Update README for bump version ([`cdbb08b`](https://github.com/szaghi/FLAP/commit/cdbb08b3e5b6f14bbcba4600cb83e4c7e750741d))
- Merge branch 'release/0.0.3' ([`ec1fd0b`](https://github.com/szaghi/FLAP/commit/ec1fd0b273e82969a4d79cd61a9d007917739924))

## [v0.0.2](https://github.com/szaghi/FLAP/tree/v0.0.2) (2016-06-09)
[Full Changelog](https://github.com/szaghi/FLAP/compare/v0.0.1...v0.0.2)
### Miscellaneous
- Add PENF dependency and lint sources

Add PENF dependency and lint sources ([`296f20c`](https://github.com/szaghi/FLAP/commit/296f20c4e5e0f70232a4ead1a7ddc2f9116748b4))
- Add StringiFor dependency and fix small bug

Add StringiFor dependency and fix small bug ([`51cab69`](https://github.com/szaghi/FLAP/commit/51cab6947929261d4146b6108ce374ae49c5d411))
- Add Travis CI config file

Add Travis CI config file

Add also makedoc.sh script ([`8771bde`](https://github.com/szaghi/FLAP/commit/8771bde2420692d86a3b43363990d177b78b4d42))
- Add codecov config file ([`c682d86`](https://github.com/szaghi/FLAP/commit/c682d86d4cb8f1c7954103750f8f00940151b86b))
- Merge branch 'release/0.0.2' ([`437b714`](https://github.com/szaghi/FLAP/commit/437b7140a6c58ee68e6169a7a5a6d27834935320))

## [v0.0.1](https://github.com/szaghi/FLAP/tree/v0.0.1) (2015-06-25)
### Miscellaneous
- Let us try to start... ([`57f9d0c`](https://github.com/szaghi/FLAP/commit/57f9d0c476e21b5dab72736c9472a1082ff29bea))
- Update CONTRIBUTING.md

Add more details in how to contribute:

+ add git configs to get the rid of unnecessary whitespaces;
+ add Fortran coding styles guidelines;

Think to add reference to some good Fortran books (Fortran Modern xxx,
Scientific Software Design the OO way, etc...). ([`c0c9cdc`](https://github.com/szaghi/FLAP/commit/c0c9cdcc3356503ab4b7f487ca9cafbbebacd956))
- First functional release

First functional release, v0.0.1.

Parser is very minimal, but support lazy find of tag value
into the parsed XML data. ([`88e06de`](https://github.com/szaghi/FLAP/commit/88e06dec99231c50829bb2b633557e7d52e7146e))


